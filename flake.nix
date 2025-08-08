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
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    nixpkgs-firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    systems.url = "github:nix-systems/default";

    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    mac-app-util.url = "github:hraban/mac-app-util";
    mac-app-util.inputs.nixpkgs.follows = "nixpkgs";

    nixos-needsreboot.url = "https://flakehub.com/f/thefossguy/nixos-needsreboot/*.tar.gz";

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
      nixos-needsreboot,
      treefmt-nix,
      ...
    }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
      treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);

      forAllSystems = nixpkgs.lib.genAttrs systems;

      commonNixOSModules = [
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        disko.nixosModules.disko
        nix-index-database.nixosModules.nix-index
      ];

      commonDarwinModules = [
        sops-nix.darwinModules.sops
        home-manager.darwinModules.home-manager
        nix-index-database.darwinModules.nix-index
      ];

      nixosHomeManagerConfig = user: host: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${user} = {
          imports = [
            ./modules/home-manager/${host}
            nixvim.homeModules.default
          ];
          _module.args = {
            inherit self inputs;
            host = host;
          };
        };
      };

      darwinHomeManagerConfig = user: host: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        nixpkgs.overlays = [ inputs.nixpkgs-firefox-darwin.overlay ];
        home-manager.users.${user} = {
          imports = [
            ./modules/home-manager/${host}
            mac-app-util.homeManagerModules.default
            nixvim.homeModules.default
          ];
          _module.args = {
            inherit self inputs;
            host = host;
          };
        };
      };
    in
    {

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
      checks = forAllSystems (pkgs: {
        formatting = treefmtEval.${pkgs.system}.config.build.check self;
      });

      darwinConfigurations = {
        macbook = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = commonDarwinModules ++ [
            mac-app-util.darwinModules.default
            {
              imports = [ ./hosts/macbook ];
              _module.args.self = self;
            }
            (darwinHomeManagerConfig "vk" "macbook")
          ];
        };
      };

      nixosConfigurations = {
        homeserver = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = commonNixOSModules ++ [
            inputs.nixos-facter-modules.nixosModules.facter
            { config.facter.reportPath = ./facter.json; }
            {
              imports = [ 
                ./hosts/homeserver 
                ./modules/disko
                ];
              _module.args.self = self;
            }
            (nixosHomeManagerConfig "zeev" "homeserver")
            nixarr.nixosModules.default
            authentik-nix.nixosModules.default
            vscode-server.nixosModules.default
          ];
        };
      };
    };
}
