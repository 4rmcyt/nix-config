{
  helpers,
  inputs,
  userName,
}: let
  # Generate home configurations for all systems
  mkHomeConfigurationsForSystem = system: let
    # Use the system parameter for each configuration
    pkgs = inputs.nixpkgs.legacyPackages.${system};
  in {
    "${userName}@desktop" = helpers.mkStandaloneHome {
      inherit pkgs;
      modules = [
        ./home-manager/desktop
        inputs.plasma-manager.homeModules.plasma-manager
        inputs.cosmic-manager.homeManagerModules.cosmic-manager
        inputs.betterfox-nix.homeModules.betterfox
        inputs.yazelix-hm.homeManagerModules.default
      ];
    };

    "${userName}@homeserver" = helpers.mkStandaloneHome {
      inherit pkgs;
      modules = [./home-manager/homeserver];
    };

    "${userName}@wsl" = helpers.mkStandaloneHome {
      inherit pkgs;
      modules = [./home-manager/wsl];
    };

    "${userName}@matebook" = helpers.mkStandaloneHome {
      inherit pkgs;
      modules = [
        ./home-manager/matebook
        inputs.betterfox-nix.homeModules.betterfox
      ];
    };
  };

  # Get all systems from the systems input
  allSystems = import inputs.systems;
in
  # Merge home configurations for all systems
  inputs.nixpkgs.lib.foldl' (
    acc: system:
      acc // (mkHomeConfigurationsForSystem system)
  ) {}
  allSystems
