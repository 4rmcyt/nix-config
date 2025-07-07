# /etc/nixos/modules/pia-vpn.nix
#
# A generic NixOS module to manage a Private Internet Access (PIA)
# WireGuard connection. It can be used by any service.

{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.pia-vpn;
in
{
  # == 1. Import Required Modules ==
  # This must be at the top level of the module, not inside the 'config' block.
  imports = [
    inputs.nix-pia-vpn.nixosModules.default
  ];

  # == 2. Define the Module's Options ==
  options.services.pia-vpn = {
    enable = mkEnableOption "PIA WireGuard VPN service";

    user = mkOption {
      type = types.str;
      default = "pia-vpn";
      description = "The user that will manage the VPN service.";
    };

    group = mkOption {
      type = types.str;
      default = "pia-vpn";
      description = "The group that services should be a part of to use the VPN.";
    };

    region = mkOption {
      type = types.str;
      default = "ca_ontario";
      description = "The PIA server region to connect to.";
    };

    portForwardScript = mkOption {
      type = with types; nullOr package;
      default = null;
      description = "A script to run when a new forwarded port is assigned.";
    };
  };

  # == 3. Implement the Module's Configuration ==
  config = mkIf cfg.enable {

    # Configure the user and group for the VPN service.
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
    };
    users.groups.${cfg.group} = {};

    # Configure the SOPS secret for PIA credentials.
    sops.secrets.pia_credentials = {
      owner = cfg.user;
      group = cfg.group;
    };

    # Configure the actual PIA VPN service using the nix-pia-vpn flake.
    services.pia-vpn = {
      enable = true;
      user = cfg.user;
      region = cfg.region;

      # These are the correct options based on the module's source code.
      environmentFile = config.sops.secrets.pia_credentials.path;
      certificateFile = ../secrets/ca.rsa.4096.crt;

      # Conditionally enable the port forwarding hook.
      portForward = mkIf (cfg.portForwardScript != null) {
        enable = true;
        script = cfg.portForwardScript;
      };
    };
  };
}
