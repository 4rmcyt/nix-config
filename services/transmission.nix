{ config, lib, pkgs, ... }:

with lib;

let
  # 'cfg' refers to OUR module's options, nested to avoid conflicts.
  cfg = config.services.transmission.vpn;

  # This script specifically updates Transmission's port. It will be passed
  # to the pia-vpn module's portForwardScript option.
  update-transmission-port-script = pkgs.writeShellScript "update-transmission-port.sh" ''
    #!${pkgs.runtimeShell}
    PORT="$1"
    echo "PIA Hook: Received new port $PORT. Updating Transmission." | ${pkgs.systemd}/bin/systemd-cat -t transmission-port-hook
    ${pkgs.sudo}/bin/sudo -u ${config.services.transmission.user} ${pkgs.transmission}/bin/transmission-remote --peerport "$PORT"
  '';
in
{
  # == 1. Define the options for this module ==
  # We nest them under services.transmission.vpn to avoid any conflicts.
  options.services.transmission.vpn = {
    enable = mkEnableOption "Transmission to run over the PIA VPN";

    downloadDir = mkOption {
      type = types.path;
      default = "/home/zeev/Downloads";
      description = "The directory where Transmission will store downloaded files.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to open the firewall for the Transmission Web UI (port 9091).";
    };
  };

  # == 2. Implement the Module's Configuration ==
  config = mkIf cfg.enable {

    # --- Configure the main PIA VPN service ---
    # This assumes services.pia-vpn.enable = true is set in configuration.nix.
    # We are just adding the port forwarding script to it.
    services.pia-vpn.portForwardScript = update-transmission-port-script;

    # --- Configure the Transmission User ---
    users.users.transmission = {
      isSystemUser = true;
      group = "transmission";
      # Add this user to the group that the pia-vpn service creates.
      # This is the key to routing its traffic through the VPN.
      extraGroups = [ config.services.pia-vpn.group "media" ];
    };
    users.groups.transmission = {};

    # --- Configure the main Transmission Service ---
    # This configures the existing NixOS module for Transmission.
    services.transmission = {
      enable = true;
      user = "transmission";
      group = "transmission";
      # --- CORRECTED OPTIONS ---
      # Settings with hyphens must be quoted.
      settings = {
        "download-dir" = cfg.downloadDir;
        "rpc-bind-address" = "127.0.0.1";
        "peer-port" = 51413; # Default, will be changed by hook.
      };
    };

    # --- Systemd Integration ---
    # Ensure transmission only starts after the VPN is up.
    systemd.services.transmission-daemon.wants = [ "pia-vpn.service" ];
    systemd.services.transmission-daemon.after = [ "pia-vpn.service" ];

    # --- Firewall ---
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 9091 ];
  };
}
