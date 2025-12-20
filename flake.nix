{
  description = "4rmcyt's Nix configuration flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    nur = {
      url = "github:nix-community/NUR";
    };

    nixos-hardware = {
      url = "github:nixos/nixos-hardware";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
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

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    pam-shim = {
      url = "github:Cu3PO42/pam_shim/next";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-anywhere = {
      url = "github:numtide/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.disko.follows = "disko";
    };

    nix-topology = {
      url = "github:oddlama/nix-topology";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    comma = {
      url = "github:nix-community/comma";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix";

    zellij-nix = {
      url = "github:a-kenji/zellij-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zjstatus = {
      url = "github:dj95/zjstatus";
    };

    nixos-jellyfin = {
      url = "github:matt1432/nixos-jellyfin";
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
    commonArgs = {
      specialArgs = {inherit inputs;};
    };

    # Home Manager global options
    globalHomeManagerOptions = {
      useGlobalPkgs = false;
      useUserPackages = true;
      backupFileExtension = "backup";
      sharedModules = [{home.enableNixpkgsReleaseCheck = false;}];
    };

    # User-specific Home Manager options
    userSpecificHomeManagerOptions = {
      nixpkgs.config.allowUnfree = true;
      sops.age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";
    };

    # Common modules for all NixOS hosts
    commonModules = [
      inputs.sops-nix.nixosModules.sops
      inputs.home-manager.nixosModules.home-manager
      inputs.nix-index-database.nixosModules.nix-index
      inputs.nixos-facter-modules.nixosModules.facter
      inputs.agenix.nixosModules.default
      inputs.vscode-server.nixosModules.default
      inputs.lix-module.nixosModules.default
      inputs.chaotic.nixosModules.nyx-cache
      inputs.chaotic.nixosModules.nyx-overlay
      inputs.ucodenix.nixosModules.default
      inputs.disko.nixosModules.disko
      inputs.nixos-jellyfin.nixosModules.default
      inputs.nix-topology.nixosModules.default
      {
        nixpkgs.config.allowUnfree = true;
        sops.age.keyFile = inputs.nixpkgs.lib.mkDefault "/root/.config/sops/age/keys.txt";
      }
    ];

    # Common Home Manager modules
    commonHomeManagerModules = [
      inputs.sops-nix.homeManagerModules.sops
      inputs.agenix.homeManagerModules.default
    ];

    # Helper function to create NixOS hosts
    mkHost = {modules}:
      inputs.nixpkgs.lib.nixosSystem (
        commonArgs
        // {
          modules =
            modules
            ++ commonModules
            ++ [
              (
                {
                  config,
                  lib,
                  ...
                }: {
                  facter.reportPath = lib.mkIf (!lib.strings.hasInfix "wsl" (lib.strings.toLower config.networking.hostName)) (lib.mkDefault ./hosts/nixos/${config.networking.hostName}/facter.json);
                }
              )
            ];
        }
      );

    # Helper function to create Home Manager configuration for NixOS modules
    mkHome = {modules}: [
      ./modules/users/${userName}
      {
        home-manager =
          globalHomeManagerOptions
          // {
            extraSpecialArgs = {inherit inputs;};
            users.${userName} =
              userSpecificHomeManagerOptions
              // {
                imports = modules ++ commonHomeManagerModules;
              };
          };
      }
    ];

    # Helper function to create standalone Home Manager configurations
    mkStandaloneHome = {
      modules,
      system ? "x86_64-linux",
    }:
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {inherit inputs;};
        modules =
          modules
          ++ commonHomeManagerModules
          ++ [
            ./modules/users/${userName}
            userSpecificHomeManagerOptions
            {
              home.stateVersion = "24.11";
            }
          ];
      };
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
      ];
      perSystem = {pkgs, ...}: {
        treefmt = import ./treefmt.nix {inherit pkgs;};
      };

      flake = {
        nixosConfigurations = {
          desktop = mkHost {
            modules =
              [
                ./hosts/nixos/desktop
                ./modules/disko/desktop
                inputs.nix-gaming.nixosModules.pipewireLowLatency
                inputs.lanzaboote.nixosModules.lanzaboote
                inputs.flatpaks.nixosModules.default
              ]
              ++ (mkHome {
                modules = [
                  ./home/desktop
                  inputs.plasma-manager.homeModules.plasma-manager
                  inputs.betterfox-nix.homeModules.betterfox
                  inputs.noctalia.homeModules.default
                  inputs.stylix.homeModules.stylix
                  inputs.pam-shim.homeModules.default
                  # inputs.cosmic-manager.homeManagerModules.default
                ];
              });
          };

          homeserver = mkHost {
            modules =
              [
                ./hosts/nixos/homeserver
                ./modules/disko/homeserver
                inputs.nixarr.nixosModules.default
                inputs.authentik-nix.nixosModules.default
              ]
              ++ (mkHome {
                modules = [./home/homeserver];
              });
          };

          wsl = mkHost {
            modules =
              [
                ./hosts/nixos/wsl
                inputs.nixos-wsl.nixosModules.wsl
              ]
              ++ (mkHome {
                modules = [./home/wsl];
              });
          };

          matebook = mkHost {
            modules =
              [
                ./hosts/nixos/matebook
                ./modules/disko/matebook
                inputs.flatpaks.nixosModules.default
              ]
              ++ (mkHome {
                modules = [
                  ./home/matebook
                  inputs.betterfox-nix.homeModules.betterfox
                ];
              });
          };
        };

        homeConfigurations = {
          "${userName}@desktop" = mkStandaloneHome {
            modules = [
              ./home/desktop
              inputs.plasma-manager.homeModules.plasma-manager
              inputs.betterfox-nix.homeModules.betterfox
              inputs.noctalia.homeModules.default
              inputs.stylix.homeModules.stylix
              inputs.pam-shim.homeModules.default
            ];
          };

          "${userName}@homeserver" = mkStandaloneHome {
            modules = [./home/homeserver];
          };

          "${userName}@wsl" = mkStandaloneHome {
            modules = [./home/wsl];
          };

          "${userName}@matebook" = mkStandaloneHome {
            modules = [
              ./home/matebook
              inputs.betterfox-nix.homeModules.betterfox
            ];
          };
        };
      };
    };
}
