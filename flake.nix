{
  description = "NixOS configuration for homeserver";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    linkwarden.url = "github:EricTheMagician/nixpkgs/linkwarden";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";

    agenix-darwin = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };  

    hyprland.url = "github:hyprwm/Hyprland";

    hypr-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };

    hyprpicker = {
      url = "github:hyprwm/hyprpicker";
      inputs.nixpkgs.follows = "hyprland/nixpkgs";
    };

    hyprlock = {
      url = "github:hyprwm/hyprlock";
      inputs = {
        hyprgraphics.follows = "hyprland/hyprgraphics";
        hyprlang.follows = "hyprland/hyprlang";
        hyprutils.follows = "hyprland/hyprutils";
        nixpkgs.follows = "hyprland/nixpkgs";
        systems.follows = "hyprland/systems";
      };
    };

    waybar.url = "github:Alexays/Waybar";

    nix-gaming.url = "github:fufexan/nix-gaming";

    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    nixarr = {
      url = "github:rasmus-kirk/nixarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim.url = "github:nix-community/nixvim";

    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    authentik-nix = {
      url = "github:nix-community/authentik-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      sops-nix,
      home-manager,
      nix-index-database,
      vscode-server,
      nixarr,
      nix-ld,
      authentik-nix,
      darwin,
      nix-homebrew,
      homebrew-bundle,
      homebrew-core,
      homebrew-cask,
      flake-compat,
      hyprland,
      hypr-contrib,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      darwinSystem = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          host = "homeserver";
          username = "zeev";
          inherit self inputs;
        };
        modules = [
          ./hosts/homeserver # This should contain everything
          vscode-server.nixosModules.default
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.zeev = import ./modules/home-manager;
          }
          sops-nix.nixosModules.sops
          {
            sops.age.keyFile = "/var/lib/sops/age.key";
            sops.defaultSopsFormat = "yaml";
          }
          nix-index-database.nixosModules.nix-index
          nixarr.nixosModules.default
          nix-ld.nixosModules.nix-ld
          inputs.authentik-nix.nixosModules.default
        ];
      };
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./hosts/desktop ];
        specialArgs = {
          username = "zeev";
          host = "desktop";
          inherit self inputs;
        };
      };
      darwinConfigurations.macbook = darwin.lib.darwinSystem {
        system = darwinSystem;
        specialArgs = {
          username = "vk";
          host = "macbook";
          inherit self inputs;
        };
        modules = [
          ./hosts/macbook
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "vk";
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "homebrew/homebrew-bundle" = homebrew-bundle;
              };
              mutableTaps = false;
            };
          }
          sops-nix.darwinModules.sops
          {
            sops.age.keyFile = "/Users/vk/.config/sops/age/keys.txt";
            sops.defaultSopsFormat = "yaml";
          }
        ];
      };
    };
}
