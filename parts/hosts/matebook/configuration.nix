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

    # Facter
    facter.reportPath = ../../../hosts/nixos/matebook/facter.json;

    # Host-specific HM imports
    # home-manager now ships its own modules/programs/noctalia.nix, which
    # re-declares programs.noctalia.enable and conflicts with
    # inputs.noctalia.homeModules.default's nix/home-module.nix. Disable the
    # nixpkgs/home-manager copy, mirroring what noctalia's own
    # nix/nixos-module.nix already does for the NixOS-side module.
    home-manager.users.${owner.username}.disabledModules = ["programs/noctalia.nix"];
    home-manager.users.${owner.username}.imports = [
      ../../../home/matebook
      inputs.noctalia.homeModules.default
    ];
  };
}
