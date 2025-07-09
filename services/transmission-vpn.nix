# /etc/nixos/services/transmission-vpn.nix
{ config, pkgs, lib, ... }:
with lib;
let
  piaInterface = config.services.pia-vpn.interface;
  startTransmission = pkgs.writeScript "start-transmission" ''
    #!${pkgs.stdenv.shell}
    IP=$(${pkgs.iproute2}/bin/ip -j addr show dev ${piaInterface} | ${pkgs.jq}/bin/jq -r '.[0].addr_info | map(select(.family == "inet"))[0].local')
    ${pkgs.transmission_3}/bin/transmission-daemon -f \
      -g "${config.services.transmission.home}/.config/transmission-daemon" \
      --bind-address-ipv4 $IP
  '';

in
{
  # PIA VPN Service Configuration
  services.pia-vpn = {
    enable = true;
    environmentFile = config.sops.secrets.pia_credentials.path;
    certificateFile = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/pia-foss/manual-connections/master/ca.rsa.4096.crt";
      sha256 = "sha256-Mumx0UM+qXYU8qFMbjWOP1fAVwzJ9rLugSaZumlsZqs=";
    };
    maxLatency = 18.0;
    portForward = {
      enable = true;
      script = ''
        ${pkgs.transmission_4}/bin/transmission-remote --port $port || true
      '';
    };
  };

  # Transmission Service Configuration
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    settings = {
      "download-dir" = "/home/zeev/Downloads";
      "rpc-bind-address" = "0.0.0.0"; # RPC will still bind here
      "rpc-whitelist" = "127.0.0.1,192.168.1.*,100.64.0.*,localhost,transmission.example.com";
      "rpc-host-whitelist-enabled" = "false";
      "rpc-whitelist-enabled" = "false";
      "incomplete-dir" = "/home/zeev/Downloads/incomplete";
      "incomplete-dir-enabled" = true;
      "watch-dir" = "/home/zeev/Downloads/torrents";
      "dht-enabled" = "true";
      "script-torrent-added-enabled" = "true";
      "script-torrent-added-filename" = "/etc/nixos/scripts/add-trackers.sh";
      "blocklist-enabled" = true;
      "blocklist-url" = "https://raw.githubusercontent.com/Naunter/BT_BlockLists/master/bt_blocklists.gz";
      # REMOVED THE PROBLEMATIC LINE: "bind-address-ipv4" is handled by 'startTransmission' script.
    };
  };

  systemd.services.transmission = {
    after = [ "pia-vpn.service" ];
    bindsTo = [ "pia-vpn.service" ];
    requires = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.ExecStart = mkForce ''
      ${startTransmission}
    '';
  };
}