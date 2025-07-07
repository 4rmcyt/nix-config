# /etc/nixos/services/transmission.nix
#
# A module to extend the official Transmission service, adding the
# necessary hooks to run it securely behind the PIA VPN service.

{ config, lib, pkgs, ... }:

with lib;

let
  # 'cfg' now refers to the official services.transmission options
  cfg = config.services.transmission;
in
{
  # == 1. Extend the official module with a new option ==
  options.services.transmission.vpn = {
    enable = mkEnableOption "that Transmission should run through the PIA VPN";
  };

  # == 2. Implement the VPN integration if enabled ==
  config = mkIf (cfg.enable && cfg.vpn.enable) {

    # This is the key: we check if both transmission and our vpn flag are enabled,
    # and if so, we layer on the VPN configuration.

    # --- Configure the main PIA VPN service ---
    # This assumes services.pia-vpn is enabled and configured elsewhere.
    # We are just ADDING the port forwarding script to it.
    services.pia-vpn.portForward.script = ''
      #!${pkgs.runtimeShell}
      PORT="$1"
      echo "PIA Hook: Received new port $PORT. Updating Transmission." | systemd-cat -t transmission-port-hook

      # Since the script runs locally, we don't need RPC authentication.
      # We just tell transmission-remote to set the new port.
      transmission-remote --peerport "$PORT" || true
    '';

    # --- Configure the Transmission User ---
    # The 'nix-pia-vpn' module creates a group named 'pia-vpn'. We add our
    # transmission user to that group to route its traffic through the VPN.
    users.users.${cfg.user}.extraGroups = [ "pia-vpn" "media" ];

    # --- Systemd Integration ---
    # Use 'bindsTo' for a stronger dependency. If pia-vpn.service is stopped,
    # transmission-daemon.service will be stopped as well.
    systemd.services.transmission-daemon.bindsTo = [ "pia-vpn.service" ];
    systemd.services.transmission-daemon.after = [ "pia-vpn.service" ];

    # --- CORRECTED: Add required packages to the hook's PATH ---
    # This ensures the port-forwarding service can find the commands it needs.
    systemd.services.pia-vpn-portforward.path = [
      pkgs.transmission_4
      pkgs.systemd # for systemd-cat
    ];
  };
}
