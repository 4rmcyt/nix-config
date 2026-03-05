# Base home-manager configuration applied to all hosts.
# Provides: sops, agenix, allowUnfree, overlays, stateVersion.
{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner stateVersion;
  system = "x86_64-linux";
in {
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
      (_final: _prev: {
        hyprsession = inputs.hyprsession.packages.${system}.default;
        danksearch = inputs.danksearch.packages.${system}.default;
      })
    ];

    sops.age.keyFile = "/home/${owner.username}/.config/sops/age/keys.txt";
  };
}
