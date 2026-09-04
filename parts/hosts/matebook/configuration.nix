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
  hmWorkstation = config.modules.homeManager.workstation;
in {
  configurations.nixos.matebook.module = {config, ...}: {
    imports = [
      nixosBase
      nixosHm
      nixosWorkstation
      ../../../hosts/nixos/matebook
      inputs.niri-flake.nixosModules.niri
      inputs.noctalia.nixosModules.default
      ../../../modules/nix/lix
    ];

    nix.settings = import ../../lib/cachix.nix "matebook" "rRhmrqqdIkcFQdMJRo27YMaeU/G+H/cABE53EV5grDY=";

    facter.reportPath = ../../../hosts/nixos + "/${config.networking.hostName}/facter.json";

    home-manager.users.${owner.username}.imports = [
      hmWorkstation
      ../../../home/matebook
      inputs.noctalia.homeModules.default
    ];
  };
}
