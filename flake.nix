{
  inputs = {
    # Core Nix ecosystem
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";

    # System management
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Desktop environment
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    flatpaks.url = "github:in-a-dil-emma/declarative-flatpak/latest";

    # Security & secrets
    agenix.url = "github:ryantm/agenix";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Performance & optimization
    auto-cpufreq = {
      url = "github:AdnanHodzic/auto-cpufreq";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-gaming.url = "github:fufexan/nix-gaming";

    # Services & applications
    authentik-nix.url = "github:nix-community/authentik-nix";
    linkwarden.url = "github:EricTheMagician/nixpkgs/linkwarden";
    nixai.url = "github:olafkfreund/nix-ai-help";
    nixarr.url = "github:rasmus-kirk/nixarr";
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # Development tools
    nix-index-database.url = "github:nix-community/nix-index-database";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    nixos-generators.url = "github:nix-community/nixos-generators";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    # Browser extensions
    betterfox-nix = {
      url = "github:HeitorAugustoLN/betterfox-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-nightly = {
      url = "github:nix-community/flake-firefox-nightly";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Non-flake inputs
    cpu-microcodes = {
      url = "github:platomav/CPUMicrocodes";
      flake = false;
    };
  };

  outputs = inputs @ {
    flake-parts,
    treefmt-nix,
    ...
  }: let
    userName = "zeev";
    helpers = import ./flakeHelpers.nix {inherit inputs userName;};
  in
    flake-parts.lib.mkFlake {
      inherit inputs;
      specialArgs = {inherit inputs;};
    } {
      systems = import inputs.systems;
      imports = [treefmt-nix.flakeModule];

      perSystem = {pkgs, ...}: {
        devShells.default = import ./devshell.nix {inherit pkgs;};
        treefmt = import ./treefmt.nix {inherit pkgs;};
      };

      flake = {
        nixosConfigurations = {
          desktop = helpers.mkHost {
            modules =
              [
                ./hosts/nixos/desktop
                ./modules/disko/desktop
                inputs.nix-gaming.nixosModules.pipewireLowLatency
                inputs.lanzaboote.nixosModules.lanzaboote
                inputs.flatpaks.nixosModules.default
              ]
              ++ (helpers.mkHome {
                modules = [
                  ./home-manager/desktop
                  inputs.plasma-manager.homeModules.plasma-manager
                  inputs.nixai.homeManagerModules.default
                  inputs.betterfox-nix.homeModules.betterfox
                ];
              });
          };

          homeserver = helpers.mkHost {
            modules =
              [
                ./hosts/nixos/homeserver
                ./modules/disko/homeserver
                inputs.nixarr.nixosModules.default
                inputs.authentik-nix.nixosModules.default
                inputs.vscode-server.nixosModules.default
              ]
              ++ (helpers.mkHome {
                modules = [./home-manager/homeserver];
              });
          };

          wsl = helpers.mkHost {
            modules =
              [
                ./hosts/nixos/wsl
                inputs.nixos-wsl.nixosModules.wsl
              ]
              ++ (helpers.mkHome {
                modules = [./home-manager/wsl];
              });
          };

          laptop = helpers.mkHost {
            modules =
              [
                ./hosts/nixos/laptop
                ./modules/disko/laptop
                inputs.flatpaks.nixosModules.default
              ]
              ++ (helpers.mkHome {
                modules = [./home-manager/laptop];
              });
          };
        };

        homeConfigurations = import ./home_configurations.nix {inherit helpers inputs userName;};
      };
    };
}
