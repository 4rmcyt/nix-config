{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.transmission;
in
{
  options.services.transmission.vpn = {
    enable = mkEnableOption "that Transmission should run through the PIA VPN";
  };

  config = mkIf (cfg.enable && cfg.vpn.enable) {
    services.pia-vpn.portForward.script = ''
      #!${pkgs.runtimeShell}
      PORT="$1"
      echo "PIA Hook: Received new port $PORT. Updating Transmission." | systemd-cat -t transmission-port-hook

      # Since the script runs locally, we don't need RPC authentication.
      # We just tell transmission-remote to set the new port.
      transmission-remote --peerport "$PORT" || true
    '';

    # Add the Transmission user to the pia-vpn group. This is essential for
    # network namespace permissions.
    users.users.${cfg.user}.extraGroups = [ "pia-vpn" "media" ];

    # Ensure Transmission starts after PIA VPN and stops if PIA VPN stops.
    systemd.services.transmission-daemon.bindsTo = [ "pia-vpn.service" ];
    systemd.services.transmission-daemon.after = [ "pia-vpn.service" ];
    
    # This is the crucial part: tell pia-vpn to put transmission-daemon
    # into its network namespace, forcing its traffic through the VPN.
    # We append "transmission-daemon" to the list of services managed by pia-vpn's network namespace.
    services.pia-vpn.networkNamespace.services = [ "transmission-daemon" ];

    systemd.services.pia-vpn-portforward.path = [
      pkgs.transmission_4
      pkgs.systemd # for systemd-cat
    ];
  };
}
