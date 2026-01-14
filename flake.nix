{
  description = "4rmcyt's Nix configuration flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ucodenix.url = "github:e-tho/ucodenix";
    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      flake = false;
    };

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.lix.follows = "lix";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Desktop environment
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    flatpaks.url = "github:in-a-dil-emma/declarative-flatpak/latest";

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

    # Browser extensions
    betterfox-nix = {
      url = "github:HeitorAugustoLN/betterfox-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
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

    hyprland.url = "github:hyprwm/Hyprland";

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
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

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    ...
  }: let
    userName = "zeev";
    system = "x86_64-linux";
    commonSubstituters = [
      "https://4rmcyt.cachix.org?priority=0"
      "https://nix-community.cachix.org?priority=1"
      "https://cache.nixos.org?priority=1"
      "https://hyprland.cachix.org?priority=1"
      "https://cache.lix.systems?priority=1"
      "https://cache.flox.dev?priority=1"
      "https://nix-gaming.cachix.org?priority=3"
      "https://devenv.cachix.org?priority=4"
      "https://nixpkgs-unfree.cachix.org?priority=5"
    ];

    commonTrustedPublicKeys = [
      "4rmcyt.cachix.org-1:yHVDqXs6TDmfSOuPbl4gcfomDK9gzTmK8FabfHLi+d8="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nqlt4="
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
    ];

    commonNixosModules = [
      inputs.sops-nix.nixosModules.sops
      inputs.home-manager.nixosModules.home-manager
      inputs.nix-index-database.nixosModules.nix-index
      inputs.nixos-facter-modules.nixosModules.facter
      inputs.agenix.nixosModules.default
      inputs.vscode-server.nixosModules.default
      inputs.ucodenix.nixosModules.default
      inputs.disko.nixosModules.disko
      inputs.nixos-jellyfin.nixosModules.default
      inputs.nix-topology.nixosModules.default
    ];

    commonHomeManagerModules = [
      inputs.sops-nix.homeManagerModules.sops
      inputs.agenix.homeManagerModules.default
    ];

    commonHomeManagerNixosConfig = {
      home-manager.useGlobalPkgs = false;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "backup";
      home-manager.sharedModules = [{home.enableNixpkgsReleaseCheck = false;}];
      home-manager.extraSpecialArgs = {inherit inputs;};
    };

    commonHomeManagerUserConfig = {
      nixpkgs.config.allowUnfree = true;
      sops.age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";
    };

    mkNixosConfig = hostName: {hasFacter ? true}:
      {
        nixpkgs.config.allowUnfree = true;
        sops.age.keyFile = nixpkgs.lib.mkDefault "/root/.config/sops/age/keys.txt";
        nix.settings = {
          extra-substituters = commonSubstituters;
          extra-trusted-public-keys = commonTrustedPublicKeys;
        };
      }
      // (
        if hasFacter
        then {facter.reportPath = ./hosts/nixos + "/${hostName}/facter.json";}
        else {}
      );

    homeFlakeHelper = import ./homeFlakeHelper.nix {
      inherit
        inputs
        nixpkgs
        home-manager
        userName
        system
        commonHomeManagerModules
        ;
    };
  in {
    nixosConfigurations = {
      desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules =
          [
            ./hosts/nixos/desktop
            ./modules/disko/desktop

            inputs.flatpaks.nixosModules.default
            inputs.nix-gaming.nixosModules.pipewireLowLatency
            inputs.lix-module.nixosModules.default
            inputs.dms.nixosModules.dank-material-shell
            inputs.dms.nixosModules.greeter
            (mkNixosConfig "desktop" {})
            ./modules/users/${userName}
            (
              commonHomeManagerNixosConfig
              // {
                home-manager.users.${userName} =
                  {
                    imports =
                      [
                        ./home/desktop
                        inputs.betterfox-nix.homeModules.betterfox
                        inputs.plasma-manager.homeModules.plasma-manager
                        inputs.stylix.homeModules.stylix
                        inputs.pam-shim.homeModules.default
                        inputs.niri.homeModules.niri
                        inputs.dms.homeModules.dank-material-shell
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
        specialArgs = {inherit inputs;};
        modules =
          [
            ./hosts/nixos/homeserver
            ./modules/disko/homeserver
            inputs.nixarr.nixosModules.default
            (mkNixosConfig "homeserver" {})
            ./modules/users/${userName}
            (
              commonHomeManagerNixosConfig
              // {
                home-manager.users.${userName} =
                  {
                    imports = [./home/homeserver] ++ commonHomeManagerModules;
                  }
                  // commonHomeManagerUserConfig;
              }
            )
          ]
          ++ commonNixosModules;
      };

      wsl = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules =
          [
            ./hosts/nixos/wsl

            inputs.nixos-wsl.nixosModules.wsl

            (mkNixosConfig "wsl" {hasFacter = false;})
            ./modules/users/${userName}
            (
              commonHomeManagerNixosConfig
              // {
                home-manager.users.${userName} =
                  {
                    imports = [./home/wsl] ++ commonHomeManagerModules;
                  }
                  // commonHomeManagerUserConfig;
              }
            )
          ]
          ++ commonNixosModules;
      };

      matebook = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules =
          [
            ./hosts/nixos/matebook
            ./modules/disko/matebook
            inputs.flatpaks.nixosModules.default
            (mkNixosConfig "matebook" {})
            ./modules/users/${userName}
            (
              commonHomeManagerNixosConfig
              // {
                home-manager.users.${userName} =
                  {
                    imports =
                      [
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

    formatter.${system} = let
      pkgs = nixpkgs.legacyPackages.${system};
      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs (import ./treefmt.nix);
    in
      treefmtEval.config.build.wrapper;

    devShells.${system} = {
      default = import ./devshell.nix {
        pkgs = nixpkgs.legacyPackages.${system};
        inherit inputs;
        cachix.pull = ["4rmcyt-all"];
      };

      cuda = import ./shells/cuda-shell.nix {
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
        };
      };
    };
  };
}
