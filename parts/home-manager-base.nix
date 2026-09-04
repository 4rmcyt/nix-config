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
      sessionVariables.PYENV_ROOT = "$HOME/.pyenv";
    };

    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.android_sdk.accept_license = true;
    nixpkgs.overlays = [
      inputs.mcp-servers-nix.overlays.default
      inputs.nur.overlays.default
      inputs.nix-vscode-extensions.overlays.default
      inputs.noctalia.overlays.default
    ];

    sops.age.keyFile = "/home/${owner.username}/.config/sops/age/keys.txt";

    xdg.userDirs.setSessionVariables = false;
  };
}
