# /etc/nixos/services/transmission.nix
#
# A module to extend the official Transmission service, adding the
# necessary hooks to run it securely behind the PIA VPN service.

{ config, lib, pkgs, ... }:

with lib;

let
  # 'cfg' now refers to the official services.transmission options
  cfg = config.services.transmission;

  # This script specifically updates Transmission's port.
  update-transmission-port-script = pkgs.writeShellScript "update-transmission-port.sh" ''
    #!${pkgs.runtimeShell}
    PORT="$1"
    echo "PIA Hook: Received new port $PORT. Updating Transmission." | ${pkgs.systemd}/bin/systemd-cat -t transmission-port-hook
    # Use sudo to run the command as the transmission user
    ${pkgs.sudo}/bin/sudo -u ${cfg.user} ${pkgs.transmission}/bin/transmission-remote --peerport "$PORT"
  '';
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
    services.pia-vpn.portForward.script = update-transmission-port-script;

    # --- Configure the Transmission User ---
    # The 'nix-pia-vpn' module creates a group named 'pia-vpn'. We add our
    # transmission user to that group to route its traffic through the VPN.
    users.users.${cfg.user}.extraGroups = [ "pia-vpn" "media" ];

    # --- Systemd Integration ---
    # Ensure transmission only starts after the VPN is up.
    systemd.services.transmission-daemon.wants = [ "pia-vpn.service" ];
    systemd.services.transmission-daemon.after = [ "pia-vpn.service" ];
  };
}
