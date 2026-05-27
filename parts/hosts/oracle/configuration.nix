# Oracle Cloud ARM host definition via Dendritic configurations.nixos option.
{
  config,
  inputs,
  ...
}: let
  nixosBase = config.modules.nixos.base;
in {
  configurations.nixos.oracle-relay.module = {lib, ...}: {
    imports = [
      nixosBase
      ../../../hosts/nixos/oracle
      inputs.headplane.nixosModules.headplane
    ];

    nixpkgs.hostPlatform = lib.mkForce "aarch64-linux";
  };
}
