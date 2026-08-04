# Base home-manager configuration applied to all hosts.
# Provides: sops, allowUnfree, overlays, stateVersion.
{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner stateVersion;
in {
  modules.homeManager.base = {
    imports = [
      inputs.sops-nix.homeManagerModules.sops
      inputs.nixvim.homeModules.nixvim
    ];

    home = {
      inherit (owner) username;
      homeDirectory = "/home/${owner.username}";
      inherit stateVersion;
    };

    nixpkgs.config.allowUnfree = true;
    nixpkgs.overlays = [
      inputs.mcp-servers-nix.overlays.default
      inputs.nur.overlays.default
      inputs.nix-vscode-extensions.overlays.default
      inputs.noctalia.overlays.default

      # Upstream version skew (as of 2026-08-04): Hyprland's CMakeLists.txt
      # requires `find_package(glaze 7...<8 QUIET)`, but nixpkgs' `glaze` has
      # moved to 8.0.0 — outside that range — so the Config-mode lookup
      # legitimately fails and CMake falls back to a network FetchContent
      # clone, which always fails in the sandbox. Pin glaze to the last 7.x
      # release for hyprland's buildInput until Hyprland bumps its own
      # requirement to accept glaze 8.
      (final: prev: let
        glaze7 = prev.glaze.overrideAttrs (_old: rec {
          version = "7.9.1";
          src = prev.fetchFromGitHub {
            owner = "stephenberry";
            repo = "glaze";
            tag = "v${version}";
            hash = "sha256-1t7jkSdvU3VnLDXQYFjk/Y8fMPYrrhY6AEs70TpOKuM=";
          };
        });
      in {
        hyprland = prev.hyprland.override {glaze = glaze7;};
      })
    ];

    sops.age.keyFile = "/home/${owner.username}/.config/sops/age/keys.txt";

    xdg.userDirs.setSessionVariables = false;
  };
}
