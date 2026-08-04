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

      # Upstream regression (as of 2026-08-04): Hyprland's CMakeLists.txt
      # does `find_package(glaze 7...<8 QUIET)` before falling back to a
      # network FetchContent clone (which always fails in the Nix sandbox).
      # glaze is a proper buildInput with a valid glazeConfig.cmake, but
      # CMake's Config-mode version-range lookup isn't resolving it — pass
      # -Dglaze_DIR explicitly so find_package(CONFIG) locates it directly.
      # Drop once fixed upstream in nixpkgs' hyprland.nix.
      (final: prev: {
        hyprland = prev.hyprland.overrideAttrs (old: {
          cmakeFlags = (old.cmakeFlags or []) ++ ["-Dglaze_DIR=${final.glaze}/share/glaze"];
        });
      })
    ];

    sops.age.keyFile = "/home/${owner.username}/.config/sops/age/keys.txt";

    xdg.userDirs.setSessionVariables = false;
  };
}
