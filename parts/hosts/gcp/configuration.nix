{config, ...}: let
  nixosBase = config.modules.nixos.base;
in {
  configurations.nixos.gcp-relay.module = {
    lib,
    inputs,
    ...
  }: {
    imports = [
      nixosBase
      ../../../hosts/nixos/gcp
      inputs.headplane.nixosModules.headplane
    ];

    disabledModules = ["services/networking/headplane.nix"];

    nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";
    nixpkgs.overlays = [inputs.headplane.overlays.default];

    home-manager.users.zeev.imports = [
      ../../../modules/TUI/starship
    ];
  };
}
