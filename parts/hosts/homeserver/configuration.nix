# Homeserver host definition via Dendritic configurations.nixos option.
{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner;
  nixosBase = config.modules.nixos.base;
in {
  # Home Assistant microvm guest — consumed by homeserver via microvm.vms.hass.flake
  configurations.nixos.hass.module = {
    imports = [
      inputs.microvm.nixosModules.microvm
      ../../../modules/services/home-assistant/vm-config.nix
    ];
  };

  configurations.nixos.homeserver.module = {...}: {
    imports = [
      nixosBase
      ../../../hosts/nixos/homeserver
      inputs.nixarr.nixosModules.default
    ];

    # Facter
    facter.reportPath = ../../../hosts/nixos/homeserver/facter.json;

    # Host-specific HM imports
    home-manager.users.${owner.username}.imports = [
      ../../../home/homeserver
    ];
  };
}
