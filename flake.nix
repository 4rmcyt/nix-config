{
  description = "NixOS configuration";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nix-gaming.cachix.org"
      "https://hyprland.cachix.org"
      "https://homeserver.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "homeserver.cachix.org-1:0vStm6koDUwET/iWYhbKpsuVO4v3UgN3510zYH9YpZU="
    ];
  };

  inputs = {
    # Core Flake Dependencies
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Secrets Management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # System Utilities
    cpu-microcodes = {
      url = "github:platomav/CPUMicrocodes";
      flake = false;
    };
    auto-cpufreq = {
      url = "github:AdnanHodzic/auto-cpufreq";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database.url = "github:nix-community/nix-index-database";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    systems.url = "github:nix-systems/default";

    # Services & Applications
    firefox-darwin = {
      url = "github:bandithedoge/nixpkgs-firefox-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixarr.url = "github:rasmus-kirk/nixarr";
    authentik-nix.url = "github:nix-community/authentik-nix";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    nixos-generators.url = "github:nix-community/nixos-generators";
    linkwarden-pr = {
      url = "github:NixOS/nixpkgs/f0809e9f3402644c0987842727cb1d3f93d2e4a6?shallow=1";
      flake = false;
    };
    # Hyprland & Wayland
    hyprland.url = "github:hyprwm/Hyprland";
    hypr-contrib.url = "github:hyprwm/contrib";
    hyprpicker.url = "github:hyprwm/hyprpicker";
    hyprlock.url = "github:hyprwm/hyprlock";
    waybar.url = "github:Alexays/Waybar";

    # Gaming
    nix-gaming.url = "github:fufexan/nix-gaming";
  };
  outputs =
    { self, flake-utils, ... }@inputs:
    let
      helpers = import ./flakeHelpers.nix inputs;
      inherit (helpers) mkNixos mkDarwin mkOutputs;
    in
    mkOutputs {
      nixosConfigurations = {
        homeserver = mkNixos "homeserver" "x86_64-linux" [
          ./hosts/nixos/homeserver
          ./modules/users/zeev
          ./modules/disko
          inputs.nixarr.nixosModules.default
          inputs.authentik-nix.nixosModules.default
          inputs.vscode-server.nixosModules.default
        ];
      };

      darwinConfigurations = {
        macbook = mkDarwin "macbook" "aarch64-darwin" [
          ./hosts/darwin/macbook
          ./modules/users/vk
        ];
      };

      treefmt-config = import ./treefmt.nix {
        pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      };
    };
}