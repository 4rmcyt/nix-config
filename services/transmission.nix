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
  # It now uses an environment file for authentication instead of sudo.
  update-transmission-port-script = pkgs.writeShellScript "update-transmission-port.sh" ''
    #!${pkgs.runtimeShell}
    PORT="$1"
    echo "PIA Hook: Received new port $PORT. Updating Transmission." | ${pkgs.systemd}/bin/systemd-cat -t transmission-port-hook

    # Export the credentials from the sops-managed file
    export $(cat ${config.sops.secrets.transmission_rpc_auth.path} | xargs)

    # Use the --authenv flag to authenticate with the exported credentials
    ${pkgs.transmission}/bin/transmission-remote --authenv --peerport "$PORT" || true
  '';
in
{
  # == 1. Extend the official module with new options ==
  options.services.transmission.vpn = {
    enable = mkEnableOption "that Transmission should run through the PIA VPN";

    # New option to specify the location of the RPC auth secret file.
    rpcAuthSecretFile = mkOption {
      type = types.path;
      description = "Path to the sops-encrypted file containing 'TR_AUTH=username:password'.";
      example = "/etc/nixos/secrets/transmission_auth.env";
    };
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

    # --- SOPS Integration for RPC Auth ---
    # Make the RPC auth secret available to the hook script.
    sops.secrets.transmission_rpc_auth = {
      source = cfg.vpn.rpcAuthSecretFile;
      owner = cfg.user; # The transmission user needs to read this.
    };

    # --- Systemd Integration ---
    # Use 'bindsTo' for a stronger dependency. If pia-vpn.service is stopped,
    # transmission-daemon.service will be stopped as well.
    systemd.services.transmission-daemon.bindsTo = [ "pia-vpn.service" ];
    systemd.services.transmission-daemon.after = [ "pia-vpn.service" ];
  };
}
