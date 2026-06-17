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
    nixpkgs.overlays = [
      inputs.headplane.overlays.default
      # Fix: ssh-wasm buildPhase only chmod's derp/derphttp but the patch also
      # touches net/netcheck — widen to the whole tailscale.com vendor tree.
      (_final: prev: {
        headplane-ssh-wasm = prev.headplane-ssh-wasm.overrideAttrs (old: {
          buildPhase =
            builtins.replaceStrings
            ["chmod -R +w vendor/tailscale.com/derp/derphttp"]
            ["chmod -R +w vendor/tailscale.com"]
            old.buildPhase;
        });
      })
    ];

    home-manager.users.zeev.imports = [
      ../../../modules/TUI/starship
    ];
  };
}
