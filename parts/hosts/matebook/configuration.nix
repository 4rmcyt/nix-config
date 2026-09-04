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

    nix.settings = {
      extra-substituters = ["https://4rmcyt-matebook.cachix.org?priority=0"];
      extra-trusted-public-keys = ["4rmcyt-matebook.cachix.org-1:rRhmrqqdIkcFQdMJRo27YMaeU/G+H/cABE53EV5grDY="];
    };

    facter.reportPath = ../../../hosts/nixos/matebook/facter.json;

    home-manager.users.${owner.username}.imports = [
      ../../../home/matebook
      inputs.noctalia.homeModules.default
    ];
  };
}
