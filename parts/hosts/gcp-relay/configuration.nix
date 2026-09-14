{config, ...}: let
  nixosBase = config.modules.nixos.base;
  nixosNixMineral = config.modules.nixos.nixMineral;
in {
  configurations.nixos.gcp-relay.module = {
    lib,
    inputs,
    pkgs,
    ...
  }: {
    imports = [
      nixosBase
      nixosNixMineral
      ../../../hosts/nixos/gcp-relay
      # No modules/nix/lix here (unlike every other host) — gcp-relay runs the
      # stock nixpkgs nix daemon on purpose.
    ];

    nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";
    nixpkgs.overlays = [
      inputs.headscale.overlays.default
    ];

    environment.systemPackages = [pkgs.fastfetch];

    nix.settings = import ../../../lib/cachix.nix "gcp" "YeeaTxEm6F3YRsHdEYcggHL3TjrdJrLOfxM6J2YLHwY=";
  };
}
