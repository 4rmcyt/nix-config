{
  description = "A highly structured NixOS configuration";

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
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Non-flake inputs
    cpu-microcodes = {
      url = "github:platomav/CPUMicrocodes";
      flake = false;
    };
  };

  outputs = {
    treefmt-nix,
    ...
  } @ inputs:
    inputs.flake-parts.lib.mkFlake
    {
      inherit inputs;
    }
    {
      systems = import inputs.systems;
      imports = [treefmt-nix.flakeModule];

      perSystem = {pkgs, ...}: {
        devShells.default = import ./devshell.nix {inherit pkgs;};
        treefmt = import ./treefmt.nix;
      };

      flake = let
        helpers = import ./flakeHelpers.nix inputs;
        inherit (helpers) mkNixos;
      in {
        nixosConfigurations = {
          desktop = mkNixos "desktop" "x86_64-linux" [
            # Host-specific configuration
            ./hosts/nixos/desktop
            ./modules/users/zeev
            ./modules/disko/desktop

            # Flake Modules
            inputs.nixos-facter-modules.nixosModules.facter
            inputs.agenix.nixosModules.default
            inputs.nix-gaming.nixosModules.pipewireLowLatency
            inputs.nix-gaming.nixosModules.platformOptimizations
            inputs.lanzaboote.nixosModules.lanzaboote

            # Inline Configuration
            {
              config.facter.reportPath = ./hosts/nixos/desktop/facter.json;
              nixpkgs.config.allowUnfree = true;
              sops.age.keyFile = "/root/.config/sops/age/keys.txt";
              home-manager = {
                useGlobalPkgs = false;
                useUserPackages = true;
                backupFileExtension = "backup";
                users.zeev = {
                  imports = [
                    ./home-manager/desktop
                    inputs.sops-nix.homeManagerModules.sops
                    inputs.agenix.homeManagerModules.default
                    inputs.plasma-manager.homeModules.plasma-manager
                    inputs.nixai.homeManagerModules.default
                  ];
                  nixpkgs.config.allowUnfree = true;
                  sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
                  _module.args = {inherit inputs;};
                };
              };
            }
          ];

          homeserver = mkNixos "homeserver" "x86_64-linux" [
            # Host-specific configuration
            ./hosts/nixos/homeserver
            ./modules/users/zeev
            ./modules/disko/homeserver

            # Flake Modules
            inputs.nixarr.nixosModules.default
            inputs.authentik-nix.nixosModules.default
            inputs.vscode-server.nixosModules.default
            inputs.nixos-facter-modules.nixosModules.facter
            inputs.agenix.nixosModules.default

            # Inline Configuration
            {
              config.facter.reportPath = ./hosts/nixos/homeserver/facter.json;
              sops.age.keyFile = "/var/lib/sops/age.key";
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                users.zeev = {
                  imports = [
                    ./home-manager/homeserver
                    inputs.sops-nix.homeManagerModules.sops
                    inputs.agenix.homeManagerModules.default
                  ];
                  sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
                };
              };
            }
          ];

          wsl = mkNixos "wsl" "x86_64-linux" [
            # Host-specific configuration
            ./hosts/nixos/wsl
            ./modules/users/zeev

            # Flake Modules
            inputs.nixos-wsl.nixosModules.wsl
            inputs.agenix.nixosModules.default

            # Inline Configuration
            {
              sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                users.zeev = {
                  imports = [
                    ./home-manager/wsl
                    inputs.sops-nix.homeManagerModules.sops
                    inputs.agenix.homeManagerModules.default
                  ];
                  sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
                };
              };
            }
          ];
        };

        # Standalone home-manager configurations
        homeConfigurations = {
          "zeev@desktop" = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
            modules = [
              ./home-manager/desktop
              inputs.sops-nix.homeManagerModules.sops
              inputs.agenix.homeManagerModules.default
              inputs.plasma-manager.homeModules.plasma-manager
              inputs.nixai.homeManagerModules.default
              {nixpkgs.config.allowUnfree = true;}
            ];
            extraSpecialArgs = {inherit inputs;};
          };
        };
      };
    };
}
