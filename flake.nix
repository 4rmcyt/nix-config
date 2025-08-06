{
  description = "NixOS configuration";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nix-gaming.cachix.org"
      "https://hyprland.cachix.org"
      "https://4rmcyt.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "4rmcyt.cachix.org-1:uKI766iybXD8uDBVexbc5BCYAfdBJ262ID4C+dl2hws="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    linkwarden.url = "github:EricTheMagician/nixpkgs/linkwarden";
    flake-schemas.url = github:DeterminateSystems/flake-schemas;

    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    
    mac-app-util.url = "github:hraban/mac-app-util";
    mac-app-util.inputs.nixpkgs.follows = "nixpkgs";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
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
      nix-darwin,
      sops-nix,
      vscode-server,
      disko,
      home-manager,
      nix-index-database,
      nixvim,
      nixarr,
      mac-app-util,
      linkwarden,
      authentik-nix,
      ...
    }@inputs:
    { 
      schemas = flake-schemas.schemas;
      nixosConfigurations = {
        homeserver = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            {
              imports = [ ./hosts/homeserver ];
              _module.args.self = self;
            }
            nixarr.nixosModules.default
            authentik-nix.nixosModules.default
            nix-index-database.nixosModules.nix-index
            sops-nix.nixosModules.sops
            vscode-server.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.zeev = {
                imports = [
                  ./modules/home-manager/homeserver
                  nixvim.homeModules.default
                ];
                _module.args.self = self;
                _module.args.host = "homeserver";
                _module.args.inputs = inputs;
              };
            }
          ];
        };
      };

      darwinConfigurations = {
        macbook = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            mac-app-util.darwinModules.default
            {
              imports = [ ./hosts/macbook ];
              _module.args.self = self;
            }
            sops-nix.darwinModules.sops
            nix-index-database.darwinModules.nix-index
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.vk = {
                imports = [
                  ./modules/home-manager/macbook
                  mac-app-util.homeManagerModules.default
                  nixvim.homeModules.default
                ];
                _module.args.self = self;
                _module.args.host = "macbook";
                _module.args.inputs = inputs;
              };
            }
          ];
        };
      };
    };
}