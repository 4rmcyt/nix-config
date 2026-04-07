# Base home-manager configuration applied to all hosts.
# Provides: sops, agenix, allowUnfree, overlays, stateVersion.
{
  config,
  inputs,
  ...
}:
let
  inherit (config.meta) owner stateVersion;
in
{
  modules.homeManager.base = {
    imports = [
      inputs.sops-nix.homeManagerModules.sops
      inputs.agenix.homeManagerModules.default
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
      (import ../overlays/claw-code.nix)
    ];

    sops.age.keyFile = "/home/${owner.username}/.config/sops/age/keys.txt";

    xdg.userDirs.setSessionVariables = false;
  };
}
