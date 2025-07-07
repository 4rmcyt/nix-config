# /etc/nixos/services/transmission-vpn.nix
#
# A NixOS module to run Transmission behind a PIA WireGuard VPN
# with automatic port forwarding.

{ config, lib, pkgs, inputs, ... }:

with lib;

let
  # A shorthand for our module's options
  cfg = config.services.transmission-vpn;

  # This script is automatically executed by the nix-pia-vpn module whenever
  # PIA assigns a new forwarded port.
  update-transmission-port-script = pkgs.writeShellScript "update-transmission-port.sh" ''
    #!${pkgs.runtimeShell}
    PORT="$1"
    echo "Received new PIA port: $PORT. Updating Transmission." | ${pkgs.systemd}/bin/systemd-cat -t update-transmission-port
    ${pkgs.sudo}/bin/sudo -u ${cfg.user} ${pkgs.transmission}/bin/transmission-remote --peerport "$PORT"
  '';

in
{
  # == 1. Import Required Modules ==
  imports = [
    inputs.nix-pia-vpn.nixosModules.default
  ];

  # == 2. Define the Module's Options ==
  options.services.transmission-vpn = {
    enable = mkEnableOption "Transmission over PIA VPN";

    user = mkOption {
      type = types.str;
      default = "transmission";
      description = "User to run Transmission and the VPN service as.";
    };

    group = mkOption {
      type = types.str;
      default = "transmission";
      description = "Group to run Transmission and the VPN service as.";
    };

    extraGroups = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "A list of extra groups to add the user to.";
    };

    downloadDir = mkOption {
      type = types.path;
      default = "/var/lib/transmission/downloads";
      description = "The directory where Transmission will store downloaded files.";
    };

    configDir = mkOption {
      type = types.path;
      default = "/var/lib/transmission";
      description = "The directory where Transmission will store its configuration.";
    };

    region = mkOption {
      type = types.str;
      default = "ca_ontario";
      description = "The PIA server region to connect to.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to open the firewall for the Transmission Web UI (port 9091).";
    };
  };


  # == 3. Implement the Module's Configuration ==
  config = mkIf cfg.enable {

    # Configure the user and group for the services.
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.configDir;
      extraGroups = cfg.extraGroups;
    };
    users.groups.${cfg.group} = {};

    # Use the main sops module to make the secret file available.
    sops.secrets.pia_credentials = {
      owner = cfg.user;
      group = cfg.group;
    };

    # Configure the PIA VPN service with the correct options.
    services.pia-vpn = {
      enable = true;
      user = cfg.user;
      region = cfg.region;

      # --- CORRECTED OPTIONS BASED ON SOURCE ---
      # The module expects an environment file for credentials.
      environmentFile = config.sops.secrets.pia_credentials.path;

      # The module requires a path to the PIA CA certificate.
      certificateFile = ../secrets/ca.rsa.4096.crt;

      portForward = {
        enable = true;
        script = update-transmission-port-script;
      };
    };

    # Configure the Transmission service.
    services.transmission = {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      download-dir = cfg.downloadDir;
      rpc-bind-address = "127.0.0.1";
      peer-port = 51413; # Default, will be changed by hook.
    };

    # Open the firewall if the option is enabled.
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 9091 ];
  };
}
