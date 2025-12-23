{
  description = "4rmcyt's Nix configuration flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    nur.url = "github:nix-community/NUR";
    nixos-hardware.url = "github:nixos/nixos-hardware";

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

    clan-core = {
      url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    zjstatus.url = "github:dj95/zjstatus";

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

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      sops-nix,
      nix-index-database,
      nixos-facter-modules,
      agenix,
      vscode-server,
      lix-module,
      chaotic,
      ucodenix,
      disko,
      nixos-jellyfin,
      nix-topology,
      nix-gaming,
      betterfox-nix,
      noctalia,
      stylix,
      pam-shim,
      lanzaboote,
      flatpaks,
      plasma-manager,
      nixarr,
      authentik-nix,
      nixos-wsl,
      ...
    }:
    let
      userName = "zeev";
      system = "x86_64-linux";

      commonNixosModules = [
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        nix-index-database.nixosModules.nix-index
        nixos-facter-modules.nixosModules.facter
        agenix.nixosModules.default
        vscode-server.nixosModules.default
        lix-module.nixosModules.default
        chaotic.nixosModules.nyx-cache
        chaotic.nixosModules.nyx-overlay
        ucodenix.nixosModules.default
        disko.nixosModules.disko
        nixos-jellyfin.nixosModules.default
        nix-topology.nixosModules.default
      ];

      commonHomeManagerModules = [
        sops-nix.homeManagerModules.sops
        agenix.homeManagerModules.default
      ];

      commonHomeManagerNixosConfig = {
        home-manager.useGlobalPkgs = false;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "backup";
        home-manager.sharedModules = [ { home.enableNixpkgsReleaseCheck = false; } ];
        home-manager.extraSpecialArgs = { inherit inputs; };
      };

      commonHomeManagerUserConfig = {
        nixpkgs.config.allowUnfree = true;
        sops.age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";
      };

      commonHomeConfig = {
        home = {
          username = userName;
          homeDirectory = "/home/${userName}";
          stateVersion = "24.11";
        };
        nixpkgs.config.allowUnfree = true;
        sops.age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";
      };

      mkNixosConfig =
        hostName:
        {
          hasFacter ? true,
        }:
        {
          nixpkgs.config.allowUnfree = true;
          sops.age.keyFile = nixpkgs.lib.mkDefault "/root/.config/sops/age/keys.txt";
        }
        // (if hasFacter then { facter.reportPath = ./hosts/nixos + "/${hostName}/facter.json"; } else { });

      homeFlakeHelper = import ./homeFlakeHelper.nix {
        inherit
          inputs
          nixpkgs
          home-manager
          userName
          system
          commonHomeManagerModules
          commonHomeConfig
          ;
      };
    in
    {
      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/nixos/desktop
            ./modules/disko/desktop

            nix-gaming.nixosModules.pipewireLowLatency
            lanzaboote.nixosModules.lanzaboote
            flatpaks.nixosModules.default

            (mkNixosConfig "desktop" { })
            ./modules/users/${userName}
            (
              commonHomeManagerNixosConfig
              // {
                home-manager.users.${userName} = {
                  imports = [
                    ./home/desktop
                    plasma-manager.homeModules.plasma-manager
                    betterfox-nix.homeModules.betterfox
                    noctalia.homeModules.default
                    stylix.homeModules.stylix
                    pam-shim.homeModules.default
                  ]
                  ++ commonHomeManagerModules;
                }
                // commonHomeManagerUserConfig;
              }
            )
          ]
          ++ commonNixosModules;
        };

        homeserver = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            # Host configuration
            ./hosts/nixos/homeserver
            ./modules/disko/homeserver

            nixarr.nixosModules.default
            authentik-nix.nixosModules.default

            (mkNixosConfig "homeserver" { })
            ./modules/users/${userName}
            (
              commonHomeManagerNixosConfig
              // {
                home-manager.users.${userName} = {
                  imports = [ ./home/homeserver ] ++ commonHomeManagerModules;
                }
                // commonHomeManagerUserConfig;
              }
            )
          ]
          ++ commonNixosModules;
        };

        wsl = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/nixos/wsl

            nixos-wsl.nixosModules.wsl

            (mkNixosConfig "wsl" { hasFacter = false; })
            ./modules/users/${userName}
            (
              commonHomeManagerNixosConfig
              // {
                home-manager.users.${userName} = {
                  imports = [ ./home/wsl ] ++ commonHomeManagerModules;
                }
                // commonHomeManagerUserConfig;
              }
            )
          ]
          ++ commonNixosModules;
        };

        matebook = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/nixos/matebook
            ./modules/disko/matebook
            flatpaks.nixosModules.default
            (mkNixosConfig "matebook" { })
            ./modules/users/${userName}
            (
              commonHomeManagerNixosConfig
              // {
                home-manager.users.${userName} = {
                  imports = [
                    ./home/matebook
                    inputs.betterfox-nix.homeModules.betterfox
                  ]
                  ++ commonHomeManagerModules;
                }
                // commonHomeManagerUserConfig;
              }
            )
          ]
          ++ commonNixosModules;
        };
      };

      inherit (homeFlakeHelper) homeConfigurations;

      formatter.${system} =
        let
          pkgs = nixpkgs.legacyPackages.${system};
          treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs (import ./treefmt.nix);
        in
        treefmtEval.config.build.wrapper;
    };
}
