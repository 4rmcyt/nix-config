{ config, lib, pkgs, ... }:

with lib;
let
  piaInterface = config.services.pia-vpn.interface;
  startTransmission = pkgs.writeScript "start-transmission" ''
    #!${pkgs.stdenv.shell}
    IP=$(${pkgs.iproute2}/bin/ip addr show dev wg0 | grep "inet" | ${pkgs.gawk}/bin/awk '{print $2}' | cut -d/ -f10)
    ${pkgs.transmission_4}/bin/transmission-daemon -f -g "${config.services.transmission.home}/.config/transmission-daemon" --bind-address-ipv4 $IP
  '';

in
{
  services = {
    pia-vpn = {
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

  transmission = {
    enable = true;
    settings = {
      download-queue-enabled = true;
      download-queue-size = 3;
      encryption = 1;
      idle-seeding-limit = 2;
      idle-seeding-limit-enabled = false;
      incomplete-dir-enabled = false;
      peer-limit-global = 1033;
      peer-limit-per-torrent = 310;
      peer-port = 61030;
      peer-port-random-high = 65535;
      peer-port-random-low = 16384;
      peer-port-random-on-start = true;
      peer-socket-tos = "lowcost";
      port-forwarding-enabled = false;
      queue-stalled-enabled = true;
      queue-stalled-minutes = 30;
      ratio-limit = 4;
      ratio-limit-enabled = true;
      rename-partial-files = true;
      download-dir = "/home/zeev/Downloads";
      rpc-enabled = true;
      rpc-bind-address = "0.0.0.0";
      rpc-whitelist = "127.0.0.1,192.168.1.*,100.64.0.*,localhost,transmission.example.com";
      rpc-whitelist-enabled = false;
      dht-enabled = "true";
      scrape-paused-torrents-enabled = true;
      seed-queue-enabled = false;
      speed-limit-up = 550;
      speed-limit-up-enabled = false;
      start-added-torrents = true;
      trash-original-torrent-files = false;
      umask = 2;
      upload-slots-per-torrent = 14;
      utp-enabled = true;
      watch-dir-enabled = false;
      script-torrent-added-enabled = true;
      script-torrent-added-filename = "/etc/nixos/scripts/add-trackers.sh";
      blocklist-enabled = true;
      blocklist-url = "https://raw.githubusercontent.com/Naunter/BT_BlockLists/master/bt_blocklists.gz";
    };
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
