{
  config,
  inputs,
  ...
}: let
  nixosBase = config.modules.nixos.base;
  nixosNixMineral = config.modules.nixos.nixMineral;
in {
  configurations.nixos.gcp-relay.module = {
    lib,
    pkgs,
    ...
  }: {
    imports = [
      nixosBase
      nixosNixMineral
      ../../../hosts/nixos/gcp-relay
      # Upstream module: disables nixpkgs' headscale module and pins its own package.
      inputs.headscale.nixosModules.default
      # No modules/nix/lix: gcp-relay runs the stock nixpkgs nix daemon on purpose.
    ];

    nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";

    environment.systemPackages = [pkgs.fastfetch];

    nix.settings = import ../../../lib/cachix.nix "gcp" "YeeaTxEm6F3YRsHdEYcggHL3TjrdJrLOfxM6J2YLHwY=";
  };
}
