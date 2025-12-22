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

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    ...
  }: let
    userName = "zeev";
    system = "x86_64-linux";
  in {
    # NixOS Configurations
    nixosConfigurations = {
      desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          # Host configuration
          ./hosts/nixos/desktop
          ./modules/disko/desktop

          # Common modules
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

          # Desktop-specific modules
          inputs.nix-gaming.nixosModules.pipewireLowLatency
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.flatpaks.nixosModules.default

          # NixOS-level configuration
          {
            nixpkgs.config.allowUnfree = true;
            sops.age.keyFile = nixpkgs.lib.mkDefault "/root/.config/sops/age/keys.txt";
            facter.reportPath = ./hosts/nixos/desktop/facter.json;
          }

          # Home Manager configuration
          ./modules/users/${userName}
          {
            home-manager.useGlobalPkgs = false;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.sharedModules = [{home.enableNixpkgsReleaseCheck = false;}];
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.users.${userName} = {
              imports = [
                ./home/desktop
                inputs.sops-nix.homeManagerModules.sops
                inputs.agenix.homeManagerModules.default
                inputs.plasma-manager.homeModules.plasma-manager
                inputs.betterfox-nix.homeModules.betterfox
                inputs.noctalia.homeModules.default
                inputs.stylix.homeModules.stylix
                inputs.pam-shim.homeModules.default
                # inputs.cosmic-manager.homeManagerModules.default
              ];
              nixpkgs.config.allowUnfree = true;
              sops.age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";
            };
          }
        ];
      };

      homeserver = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          # Host configuration
          ./hosts/nixos/homeserver
          ./modules/disko/homeserver

          # Common modules
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

          # Homeserver-specific modules
          inputs.nixarr.nixosModules.default
          inputs.authentik-nix.nixosModules.default

          # NixOS-level configuration
          {
            nixpkgs.config.allowUnfree = true;
            sops.age.keyFile = nixpkgs.lib.mkDefault "/root/.config/sops/age/keys.txt";
            facter.reportPath = ./hosts/nixos/homeserver/facter.json;
          }

          # Home Manager configuration
          ./modules/users/${userName}
          {
            home-manager.useGlobalPkgs = false;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.sharedModules = [{home.enableNixpkgsReleaseCheck = false;}];
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.users.${userName} = {
              imports = [
                ./home/homeserver
                inputs.sops-nix.homeManagerModules.sops
                inputs.agenix.homeManagerModules.default
              ];
              nixpkgs.config.allowUnfree = true;
              sops.age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";
            };
          }
        ];
      };

      wsl = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          # Host configuration
          ./hosts/nixos/wsl

          # Common modules
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

          # WSL-specific modules
          inputs.nixos-wsl.nixosModules.wsl

          # NixOS-level configuration
          {
            nixpkgs.config.allowUnfree = true;
            sops.age.keyFile = nixpkgs.lib.mkDefault "/root/.config/sops/age/keys.txt";
          }

          # Home Manager configuration
          ./modules/users/${userName}
          {
            home-manager.useGlobalPkgs = false;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.sharedModules = [{home.enableNixpkgsReleaseCheck = false;}];
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.users.${userName} = {
              imports = [
                ./home/wsl
                inputs.sops-nix.homeManagerModules.sops
                inputs.agenix.homeManagerModules.default
              ];
              nixpkgs.config.allowUnfree = true;
              sops.age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";
            };
          }
        ];
      };

      matebook = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          # Host configuration
          ./hosts/nixos/matebook
          ./modules/disko/matebook

          # Common modules
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

          # Matebook-specific modules
          inputs.flatpaks.nixosModules.default

          # NixOS-level configuration
          {
            nixpkgs.config.allowUnfree = true;
            sops.age.keyFile = nixpkgs.lib.mkDefault "/root/.config/sops/age/keys.txt";
            facter.reportPath = ./hosts/nixos/matebook/facter.json;
          }

          # Home Manager configuration
          ./modules/users/${userName}
          {
            home-manager.useGlobalPkgs = false;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.sharedModules = [{home.enableNixpkgsReleaseCheck = false;}];
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.users.${userName} = {
              imports = [
                ./home/matebook
                inputs.sops-nix.homeManagerModules.sops
                inputs.agenix.homeManagerModules.default
                inputs.betterfox-nix.homeModules.betterfox
              ];
              nixpkgs.config.allowUnfree = true;
              sops.age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";
            };
          }
        ];
      };
    };

    # Standalone Home Manager Configurations
    homeConfigurations = {
      "${userName}@desktop" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {inherit inputs;};
        modules = [
          ./home/desktop
          inputs.sops-nix.homeManagerModules.sops
          inputs.agenix.homeManagerModules.default
          inputs.plasma-manager.homeModules.plasma-manager
          inputs.betterfox-nix.homeModules.betterfox
          inputs.noctalia.homeModules.default
          inputs.stylix.homeModules.stylix
          inputs.pam-shim.homeModules.default
          {
            home = {
              username = userName;
              homeDirectory = "/home/${userName}";
              stateVersion = "24.11";
            };
            nixpkgs.config.allowUnfree = true;
            sops.age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";
          }
        ];
      };

      "${userName}@homeserver" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {inherit inputs;};
        modules = [
          ./home/homeserver
          inputs.sops-nix.homeManagerModules.sops
          inputs.agenix.homeManagerModules.default
          {
            home = {
              username = userName;
              homeDirectory = "/home/${userName}";
              stateVersion = "24.11";
            };
            nixpkgs.config.allowUnfree = true;
            sops.age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";
          }
        ];
      };

      "${userName}@wsl" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {inherit inputs;};
        modules = [
          ./home/wsl
          inputs.sops-nix.homeManagerModules.sops
          inputs.agenix.homeManagerModules.default
          {
            home = {
              username = userName;
              homeDirectory = "/home/${userName}";
              stateVersion = "24.11";
            };
            nixpkgs.config.allowUnfree = true;
            sops.age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";
          }
        ];
      };

      "${userName}@matebook" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {inherit inputs;};
        modules = [
          ./home/matebook
          inputs.sops-nix.homeManagerModules.sops
          inputs.agenix.homeManagerModules.default
          inputs.betterfox-nix.homeModules.betterfox
          {
            home = {
              username = userName;
              homeDirectory = "/home/${userName}";
              stateVersion = "24.11";
            };
            nixpkgs.config.allowUnfree = true;
            sops.age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";
          }
        ];
      };
    };

    # Formatter
    formatter.${system} = let
      pkgs = nixpkgs.legacyPackages.${system};
      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs (import ./treefmt.nix);
    in
      treefmtEval.config.build.wrapper;
  };
}
