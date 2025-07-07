# /etc/nixos/modules/pia-vpn.nix
#
# A generic local module to abstract the configuration of the
# nix-pia-vpn flake. It defines its own options under "my.pia-vpn"
# to avoid conflicts with the flake's "services.pia-vpn".

{ config, lib, pkgs, inputs, ... }:

with lib;

let
  # 'cfg' refers to OUR module's options, under the unique name "my.pia-vpn"
  cfg = config.my.pia-vpn;
in
{
  # == 1. Import the module from the flake ==
  # This makes the flake's options available for us to configure.
  imports = [
    inputs.nix-pia-vpn.nixosModules.default
  ];

  # == 2. Define OUR module's options ==
  options.my.pia-vpn = {
    enable = mkEnableOption "a generic PIA VPN service";

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

  # == 3. Implement the module's configuration ==
  # This section uses our options to configure the flake's module.
  config = mkIf cfg.enable {

    # Configure the user and group for the VPN service itself.
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

    # Configure the actual PIA VPN service from the flake.
    # Note the namespace is "services.pia-vpn".
    services.pia-vpn = {
      enable = true;
      user = cfg.user;
      region = cfg.region;
      environmentFile = config.sops.secrets.pia_credentials.path;
      certificateFile = ../secrets/ca.rsa.4096.crt;

      # Conditionally enable the port forwarding hook if a script is provided.
      portForward = mkIf (cfg.portForwardScript != null) {
        enable = true;
        script = cfg.portForwardScript;
      };
    };
  };
}
