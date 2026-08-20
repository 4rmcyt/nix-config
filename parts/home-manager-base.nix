# Base home-manager configuration applied to all hosts.
# Provides: sops, allowUnfree, android SDK license acceptance, overlays, stateVersion.
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
    nixpkgs.config.android_sdk.accept_license = true;
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
      (_final: prev: let
        glaze7 = prev.glaze.overrideAttrs (_old: rec {
          version = "7.9.1";
          src = prev.fetchFromGitHub {
            owner = "stephenberry";
            repo = "glaze";
            tag = "v${version}";
            hash = "sha256-NRRq5MGF2f5PW0teYnq58ELzson+U6KHVPaY6r30KLA=";
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
