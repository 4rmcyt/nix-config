{
  config,
  inputs,
  ...
}: let
  nixosBase = config.modules.nixos.base;
in {
  configurations.nixos.gcp-relay.module = {lib, ...}: {
    imports = [
      nixosBase
      ../../../hosts/nixos/gcp
      inputs.headplane.nixosModules.headplane
    ];

    nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";
  };
}
