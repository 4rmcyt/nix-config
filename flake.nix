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

    cpu-microcodes = {
      url = "github:platomav/CPUMicrocodes";
      flake = false;
    };
    ucodenix.url = "github:e-tho/ucodenix";
    ucodenix.inputs.cpu-microcodes.follows = "cpu-microcodes";

    auto-cpufreq.url = "github:AdnanHodzic/auto-cpufreq";
    auto-cpufreq.inputs.nixpkgs.follows = "nixpkgs";

    # NixOS-specific inputs
    linkwarden.url = "github:EricTheMagician/nixpkgs/linkwarden";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    nixos-needsreboot.url = "https://flakehub.com/f/thefossguy/nixos-needsreboot/*.tar.gz";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    nixarr.url = "github:rasmus-kirk/nixarr";
    nixos-generators.url = "github:nix-community/nixos-generators";
    authentik-nix.url = "github:nix-community/authentik-nix";

    hyprland.url = "github:hyprwm/Hyprland";
    hypr-contrib.url = "github:hyprwm/contrib";
    hyprpicker.url = "github:hyprwm/hyprpicker";
    hyprlock.url = "github:hyprwm/hyprlock";
    waybar.url = "github:Alexays/Waybar";
    nix-gaming.url = "github:fufexan/nix-gaming";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Common inputs
    treefmt-nix.url = "github:numtide/treefmt-nix";
    systems.url = "github:nix-systems/default";

    agenix = {
      url = "github:ryantm/agenix";
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

    nixvim.url = "github:nix-community/nixvim";
  };

  outputs =
    {
      self,
      nixpkgs,
      sops-nix,
      vscode-server,
      disko,
      home-manager,
      nix-index-database,
      nixvim,
      nixarr,
      authentik-nix,
      nixos-needsreboot,
      treefmt-nix,
      auto-cpufreq,
      ucodenix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

      commonNixOSModules = [
        sops-nix.nixosModules.sops
        {sops.age.keyFile = "/var/lib/sops/age.key";}
        home-manager.nixosModules.home-manager
        disko.nixosModules.disko
        nix-index-database.nixosModules.nix-index
        auto-cpufreq.nixosModules.default
        ucodenix.nixosModules.default
        inputs.nixos-facter-modules.nixosModules.facter
        { config.facter.reportPath = ./facter.json; }
      ];

      nixosHomeManagerConfig = user: host: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        sops-nix.homeManagerModules.sops
        {
          sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
        }
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
    in
    {
      formatter.${system} = pkgs.nixfmt-tree;
      checks.${system}.formatting = treefmtEval.config.build.check self;

      nixosConfigurations = {
        homeserver = nixpkgs.lib.nixosSystem {
          inherit system;
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
