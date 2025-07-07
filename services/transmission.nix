{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.transmission;
in
{
  options.services.transmission.vpn = {
    enable = mkEnableOption "that Transmission should run through the PIA VPN";
  };

  # All top-level configuration goes inside this 'config' attribute
  config = {
    # == Core Transmission Service Configuration ==
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

    # == Ensure the transmission user and group exist ==
    users.users.transmission = {
      isSystemUser = true;
      group = "transmission";
      home = "/var/lib/transmission";
    };
    users.groups.transmission = {};

    # == Conditional VPN integration (your existing block) ==
    # This mkIf block gets merged with the unconditional config above.
    # The 'lib.mkIf' function effectively merges its result into the parent attribute set.
    (mkIf (cfg.enable && cfg.vpn.enable) {
      services.pia-vpn.portForward.script = ''
        #!${pkgs.runtimeShell}
        PORT="$1"
        echo "PIA Hook: Received new port $PORT. Updating Transmission." | systemd-cat -t transmission-port-hook
        transmission-remote --peerport "$PORT" || true
      '';

      users.users.${cfg.user}.extraGroups = [ "pia-vpn" "media" ];

      systemd.services.transmission-daemon.bindsTo = [ "pia-vpn.service" ];
      systemd.services.transmission-daemon.after = [ "pia-vpn.service" ];

      systemd.services.pia-vpn-portforward.path = [
        pkgs.transmission_4
        pkgs.systemd
      ];
    })
  };
}
