{config, ...}: let
  nixosBase = config.modules.nixos.base;
in {
  configurations.nixos.gcp-relay.module = {
    lib,
    pkgs,
    inputs,
    ...
  }: {
    imports = [
      nixosBase
      ../../../hosts/nixos/gcp
    ];

    nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";

    # nixpkgs ships headplane 0.6.2; override to 0.6.3 (path traversal security fix)
    services.headplane.package = inputs.headplane.packages.${pkgs.system}.headplane;
  };
}
