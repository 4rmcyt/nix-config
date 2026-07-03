# Router (Sophos SG110/120) host definition via Dendritic configurations.nixos option.
# x86_64, Intel Atom D525, legacy BIOS, headless appliance.
{config, ...}: let
  inherit (config.meta) owner;
  nixosBase = config.modules.nixos.base;
in {
  configurations.nixos.router.module = {lib, ...}: {
    imports = [
      nixosBase
      ../../../hosts/nixos/router
      ../../../modules/nix/lix
    ];

    nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";

    home-manager.users.${owner.username}.imports = [
      ../../../home/router
    ];
  };
}
