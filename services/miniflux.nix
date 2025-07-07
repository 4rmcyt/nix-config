{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.transmission;
in
{
  options.services.transmission.vpn = {
    enable = mkEnableOption "that Transmission should run through the PIA VPN";
  };

  config = {
    services.transmission = {
      enable = true;
      user = "transmission";
      group = "transmission";
      home = "/var/lib/transmission";

      port = 9091;

      settings = {
        rpc-enabled = true;
        rpc-whitelist-enabled = true;
        rpc-whitelist = "127.0.0.1";
        rpc-url = "/";
        rpc-authentication-required = false;

        download-dir = "/var/lib/transmission/downloads";
        incomplete-dir-enabled = true;
        incomplete-dir = "/var/lib/transmission/incomplete";
        peer-port = 51413;
      };
    };

    users.users.transmission = {
      isSystemUser = true;
      group = "transmission";
      home = "/var/lib/transmission";
    };
    users.groups.transmission = {};

  } // (mkIf (cfg.enable && cfg.vpn.enable) {
    services.pia-vpn.portForward.script = ''
      #!${pkgs.runtimeShell}
      PORT="$1"
      echo "PIA Hook: Received new port $PORT. Updating Transmission." | systemd-cat -t transmission-port-hook
      transmission-remote --peerport "$PORT" || true
    '';

    users.users.${cfg.user}.extraGroups = [ "pia-vpn" "media" ];

    systemd.services.transmission-daemon = { # <--- ENSURE THIS BLOCK IS HERE
      bindsTo = [ "pia-vpn.service" ];
      after = [
        "pia-vpn.service"
        "network-online.target" # <--- ADD THIS LINE
      ];
      # Optional: Add Wants to explicitly state a dependency on network-online.target
      # Wants = [ "network-online.target" ];
      # Optional: Ensure it restarts if it fails due to network issues
      # restart = "on-failure";
      # restartSec = "10s"; # Wait 10 seconds before restarting
    };

    systemd.services.pia-vpn-portforward.path = [
      pkgs.transmission_4
      pkgs.systemd
    ];
  });
}
