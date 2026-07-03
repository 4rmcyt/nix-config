# Matebook host definition via Dendritic configurations.nixos option.
{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner;
  nixosBase = config.modules.nixos.base;
  nixosHm = config.modules.nixos.hm;
  nixosWorkstation = config.modules.nixos.workstation;
in {
  configurations.nixos.matebook.module = {...}: {
    imports = [
      nixosBase
      nixosHm
      nixosWorkstation
      ../../../hosts/nixos/matebook
      inputs.niri-flake.nixosModules.niri
      inputs.noctalia.nixosModules.default
      ../../../modules/nix/lix
    ];

    # Facter
    facter.reportPath = ../../../hosts/nixos/matebook/facter.json;

    # Host-specific HM imports
    home-manager.users.${owner.username}.imports = [
      ../../../home/matebook
      inputs.noctalia.homeModules.default
    ];
  };
}
