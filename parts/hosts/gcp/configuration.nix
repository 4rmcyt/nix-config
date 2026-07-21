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
    ];

    nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";
    nixpkgs.overlays = [
      inputs.headscale.overlays.default
    ];
  };
}
