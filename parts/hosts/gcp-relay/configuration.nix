{config, ...}: let
  nixosBase = config.modules.nixos.base;
in {
  configurations.nixos.gcp-relay.module = {
    lib,
    inputs,
    pkgs,
    ...
  }: {
    imports = [
      nixosBase
      ../../../hosts/nixos/gcp-relay
      # No modules/nix/lix here (unlike every other host) — gcp-relay runs the
      # stock nixpkgs nix daemon on purpose.
    ];

    nixpkgs.hostPlatform = lib.mkForce "x86_64-linux";
    nixpkgs.overlays = [
      inputs.headscale.overlays.default
    ];

    environment.systemPackages = [pkgs.fastfetch];

    nix.settings = {
      extra-substituters = ["https://4rmcyt-gcp.cachix.org?priority=0"];
      extra-trusted-public-keys = ["4rmcyt-gcp.cachix.org-1:YeeaTxEm6F3YRsHdEYcggHL3TjrdJrLOfxM6J2YLHwY="];
    };
  };
}
