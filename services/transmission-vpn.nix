# /etc/nixos/services/transmission-vpn.nix
{ config, pkgs, lib, ... }:

let
  # Define the PIA VPN interface name.
  # This variable is needed by the startTransmission script.
  piaInterface = config.services.pia-vpn.interface;

  # This script will fetch the PIA VPN interface's IP and use it to start transmission-daemon.
  startTransmission = pkgs.writeScript "start-transmission" ''
    #!${pkgs.stdenv.shell}
    set -euo pipefail # Exit on error, unset variables, and pipe failures

    # Get the IP address of the PIA VPN interface
    IP=$(${pkgs.iproute2}/bin/ip -j addr show dev ${piaInterface} | ${pkgs.jq}/bin/jq -r '.[0].addr_info | map(select(.family == "inet"))[0].local')

    # Basic check to ensure an IP was retrieved. Exit if not to prevent leaks.
    if [ -z "$IP" ] || [ "$IP" = "null" ]; then
      echo "Error: Could not determine IP address for ${piaInterface}. Transmission will not start." >&2
      exit 1 # Indicate failure to systemd
    fi

    echo "Starting transmission-daemon, binding to IP: $IP on interface ${piaInterface}"

    # Launch transmission-daemon in the foreground (-f)
    # Specify the configuration directory (-g)
    # Bind torrent traffic to the dynamically obtained IP (--bind-address-ipv4)
    # Note: rpc-bind-address will still be controlled by settings.json
    exec ${pkgs.transmission_4}/bin/transmission-daemon -f \
      -g "${config.services.transmission.home}/.config/transmission-daemon" \
      --bind-address-ipv4 "$IP"
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
      "rpc-whitelist" = "127.0.0.1,192.168.1.*,100.64.0.*,localhost,transmission.labhome.work";
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

  # Custom systemd unit configuration for Transmission to depend on PIA VPN
  systemd.services.transmission = {
    after = [ "pia-vpn.service" ];
    bindsTo = [ "pia-vpn.service" ]; # If pia-vpn stops, transmission stops
    requires = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.ExecStart = lib.mkForce ''
      ${startTransmission}
    '';
  };

  # Define the 'transmission' system user and add it to necessary groups.
  users.groups.transmission = { }; # Ensure the group is defined
  users.users.transmission = {
    isSystemUser = true;
    group = "transmission";
    extraGroups = [
      "media"
      "users"
      "pia-vpn"
    ];
  };
}