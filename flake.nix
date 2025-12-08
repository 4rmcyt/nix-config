{
  inputs = {
    # Core Nix ecosystem
    empty-flake.url = "github:4rmcyt/empty-flake";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-systems.url = "github:nix-systems/default";
    systems.url = "github:nix-systems/default";

    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "nix-systems";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      flake = false;
    };

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.lix.follows = "lix";
    };

    ucodenix.url = "github:e-tho/ucodenix";

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
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Desktop environment
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    flatpaks.url = "github:in-a-dil-emma/declarative-flatpak/latest";

    cosmic-applets-collection = {
      url = "github:wingej0/ext-cosmic-applets-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cosmic-manager = {
      url = "github:HeitorAugustoLN/cosmic-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Security & secrets
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Performance & optimization
    auto-cpufreq = {
      url = "github:AdnanHodzic/auto-cpufreq";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Services & applications
    authentik-nix = {
      url = "github:nix-community/authentik-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixarr = {
      url = "github:rasmus-kirk/nixarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-marketplace = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Development tools
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # microvm = {
    #   url = "github:microvm-nix/microvm.nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

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

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
      inputs.flake-compat.follows = "empty-flake";
    };
    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.disko.follows = "empty-flake";
      inputs.nixos-stable.follows = "empty-flake";
      inputs.nixos-images.follows = "empty-flake";
      inputs.treefmt-nix.follows = "empty-flake";
    };

    nixcord = {
      url = "github:kaylorben/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "empty-flake";
      inputs.flake-parts.follows = "flake-parts";
    };

    zellij-nix = {
      url = "github:a-kenji/zellij-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Non-flake inputs
    cpu-microcodes = {
      url = "github:platomav/CPUMicrocodes";
      flake = false;
    };
    nushell-scripts = {
      url = "github:nushell/nu_scripts";
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
    flake-parts.lib.mkFlake
    {
      inherit inputs;
      specialArgs = {inherit inputs;};
    }
    {
      systems = import inputs.systems;
      imports = [
        treefmt-nix.flakeModule
        inputs.devshell.flakeModule
      ];
      perSystem = {pkgs, ...}: {
        devshells = import ./devshell.nix {inherit pkgs;};
        treefmt = import ./treefmt.nix {inherit pkgs;};
      };

      flake = {
        nixosConfigurations = {
          desktop = helpers.mkHost {
            modules =
              [
                ./hosts/nixos/desktop
                ./modules/disko/desktop
                inputs.disko.nixosModules.disko
                inputs.nix-gaming.nixosModules.pipewireLowLatency
                inputs.lanzaboote.nixosModules.lanzaboote
                inputs.flatpaks.nixosModules.default
                inputs.chaotic.nixosModules.nyx-cache
                inputs.chaotic.nixosModules.nyx-overlay
                inputs.lix-module.nixosModules.default
                inputs.ucodenix.nixosModules.default
              ]
              ++ (helpers.mkHome {
                modules = [
                  ./home/desktop
                  inputs.plasma-manager.homeModules.plasma-manager
                  inputs.betterfox-nix.homeModules.betterfox
                  inputs.cosmic-manager.homeManagerModules.default
                ];
              });
          };

          homeserver = helpers.mkHost {
            modules =
              [
                ./hosts/nixos/homeserver
                ./modules/disko/homeserver
                inputs.disko.nixosModules.disko
                inputs.nixarr.nixosModules.default
                inputs.authentik-nix.nixosModules.default
                inputs.vscode-server.nixosModules.default
                inputs.chaotic.nixosModules.nyx-cache
                inputs.chaotic.nixosModules.nyx-overlay
                inputs.lix-module.nixosModules.default
              ]
              ++ (helpers.mkHome {
                modules = [./home/homeserver];
              });
          };

          wsl = helpers.mkHost {
            modules =
              [
                ./hosts/nixos/wsl
                inputs.nixos-wsl.nixosModules.wsl
                inputs.lix-module.nixosModules.default
                inputs.vscode-server.nixosModules.default
              ]
              ++ (helpers.mkHome {
                modules = [./home/wsl];
              });
          };

          matebook = helpers.mkHost {
            modules =
              [
                ./hosts/nixos/matebook
                ./modules/disko/matebook
                inputs.disko.nixosModules.disko
                inputs.flatpaks.nixosModules.default
                inputs.chaotic.nixosModules.nyx-cache
                inputs.chaotic.nixosModules.nyx-overlay
                inputs.lix-module.nixosModules.default
              ]
              ++ (helpers.mkHome {
                modules = [
                  ./home/matebook
                  inputs.betterfox-nix.homeModules.betterfox
                ];
              });
          };

          installer-desktop = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {inherit inputs;};
            modules = [
              ./hosts/installer/desktop
              inputs.flatpaks.nixosModules.default
              inputs.sops-nix.nixosModules.sops
              inputs.disko.nixosModules.disko
              inputs.chaotic.nixosModules.nyx-cache
              inputs.chaotic.nixosModules.nyx-overlay
              {nixpkgs.config.allowUnfree = true;}
            ];
          };

          installer-homeserver = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {inherit inputs;};
            modules = [
              ./hosts/installer/homeserver
              inputs.sops-nix.nixosModules.sops
              inputs.disko.nixosModules.disko
              {nixpkgs.config.allowUnfree = true;}
            ];
          };

          installer-matebook = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {inherit inputs;};
            modules = [
              ./hosts/installer/matebook
              inputs.sops-nix.nixosModules.sops
              inputs.disko.nixosModules.disko
              {nixpkgs.config.allowUnfree = true;}
            ];
          };
        };

        # Standalone home-manager configurations
        homeConfigurations = import ./flakeHelpersHome.nix {inherit helpers inputs userName;};

        # Deploy-rs configuration for remote deployments
        deploy.nodes = {
          homeserver = {
            hostname = "homeserver";
            profiles.system = {
              sshUser = "zeev";
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos inputs.self.nixosConfigurations.homeserver;
              user = "root";
            };
          };
        };

        # Check deploy-rs configurations
        checks = builtins.mapAttrs (_system: deployLib: deployLib.deployChecks inputs.self.deploy) inputs.deploy-rs.lib;
      };
    };
}
