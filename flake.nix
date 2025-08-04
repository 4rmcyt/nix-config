{
  description = "NixOS configuration for homeserver";

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
    flake-utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    disko.url = "github:nix-community/disko";
    sops-nix.url = "github:Mic92/sops-nix";
    agenix.url = "github:ryantm/agenix";
    home-manager.url = "github:nix-community/home-manager";
    darwin.url = "github:LnL7/nix-darwin/master";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-bundle = { url = "github:homebrew/homebrew-bundle"; flake = false; };
    homebrew-core = { url = "github:homebrew/homebrew-core"; flake = false; };
    homebrew-cask = { url = "github:homebrew/homebrew-cask"; flake = false; };
    hyprland.url = "github:hyprwm/Hyprland";
    hypr-contrib.url = "github:hyprwm/contrib";
    hyprpicker.url = "github:hyprwm/hyprpicker";
    hyprlock.url = "github:hyprwm/hyprlock";
    waybar.url = "github:Alexays/Waybar";
    nix-ld.url = "github:Mic92/nix-ld";
    nixvim.url = "github:nix-community/nixvim";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nixos-generators.url = "github:nix-community/nixos-generators";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    nixarr.url = "github:rasmus-kirk/nixarr";
    authentik-nix.url = "github:nix-community/authentik-nix";
    linkwarden.url = "github:EricTheMagician/nixpkgs/linkwarden";
    nix-gaming.url = "github:fufexan/nix-gaming";
    snowfall-lib.url = "github:snowfallorg/lib";
    # Ensure all inputs that depend on nixpkgs use the same one
    
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    nix-ld.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.inputs.nixpkgs.follows = "nixpkgs";
    nixarr.inputs.nixpkgs.follows = "nixpkgs";
    authentik-nix.inputs.nixpkgs.follows = "nixpkgs";
    linkwarden.inputs.nixpkgs.follows = "nixpkgs";
    nix-gaming.inputs.nixpkgs.follows = "nixpkgs";
    snowfall-lib.inputs.nixpkgs.follows = "nixpkgs";
    
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      lib = {
        mkNixosSystem = { system ? "x86_64-linux", host, username, modules }:
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = { inherit inputs host username; };
            modules = [
              inputs.disko.nixosModules.disko
              inputs.sops-nix.nixosModules.sops
              inputs.home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.extraSpecialArgs = { inherit inputs host username; };
              }
              inputs.nix-index-database.nixosModules.nix-index
              inputs.vscode-server.nixosModules.default
              inputs.nixarr.nixosModules.default
              inputs.nix-ld.nixosModules.nix-ld
              inputs.authentik-nix.nixosModules.default
            ] ++ modules;
          };

        mkDarwinSystem = { system ? "aarch64-darwin", host, username, modules }:
          inputs.darwin.lib.darwinSystem { # <-- No parenthesis needed
            inherit system;
            specialArgs = { inherit inputs host username; } // {
              homebrew-core = inputs.homebrew-core;
              homebrew-cask = inputs.homebrew-cask;
              homebrew-bundle = inputs.homebrew-bundle;
            };

            modules = [
              inputs.sops-nix.darwinModules.sops
              inputs.home-manager.darwinModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.extraSpecialArgs = { inherit inputs host username; };
              }
              inputs.nix-homebrew.darwinModules.nix-homebrew
              {
                nix-homebrew = {
                  enable = true;
                  enableRosetta = true;
                  user = username;
                  taps = {
                    "homebrew/homebrew-core" = inputs.homebrew-core;
                    "homebrew/homebrew-cask" = inputs.homebrew-cask;
                    "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
                  };
                  mutableTaps = false;
                };
              }
            ] ++ modules;
          };
      };
    in
    {
      nixosConfigurations = {
        homeserver = lib.mkNixosSystem {
          host = "homeserver";
          username = "zeev";
          modules = [
            ./hosts/homeserver
            { home-manager.users.zeev = import ./modules/home-manager; }
          ];
        };
      };

      darwinConfigurations = {
        macbook = lib.mkDarwinSystem {
          system = "aarch64-darwin";
          host = "macbook";
          username = "vk";
          modules = [ ./hosts/macbook ];
        };
      };
    };
}

