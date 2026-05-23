# Provides standalone homeConfigurations outputs for `nh home switch`.
# Each entry mirrors the HM config embedded in the corresponding NixOS host.
{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner stateVersion;
  hmBase = config.modules.homeManager.base;

  mkHome = {
    system,
    extraModules ? [],
  }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      extraSpecialArgs = {inherit inputs;};
      modules =
        [
          hmBase
          {
            home.stateVersion = stateVersion;
            home.username = owner.username;
            home.homeDirectory = "/home/${owner.username}";
          }
        ]
        ++ extraModules;
    };
in {
  flake.homeConfigurations = {
    "${owner.username}@desktop" = mkHome {
      system = "x86_64-linux";
      extraModules = [
        "${inputs.self}/home/desktop"
        inputs.betterfox-nix.homeModules.betterfox
        inputs.stylix.homeModules.stylix
        inputs.noctalia.homeModules.default
      ];
    };
  };
}
