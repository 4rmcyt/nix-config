{
  description = "NixOS configuration";

  nixConfig = {
    extra-substituters = [
      "https://cachix.cachix.org"
      "https://nix-community.cachix.org"
      "https://nix-gaming.cachix.org"
      "https://hyprland.cachix.org"
      "https://homeserver.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "homeserver.cachix.org-1:0vStm6koDUwET/iWYhbKpsuVO4v3UgN3510zYH9YpZU="
    ];
  };

  inputs = {
    flake-utils.url = "github:numtide/flake-utils?shallow=true";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable?shallow=true";

    # System Utilities
    auto-cpufreq.url = "github:AdnanHodzic/auto-cpufreq?shallow=true";
    disko.url = "github:nix-community/disko?shallow=true";
    nix-ld.url = "github:Mic92/nix-ld?shallow=true";
    sops-nix.url = "github:Mic92/sops-nix?shallow=true";
    nix-index-database.url = "github:nix-community/nix-index-database?shallow=true";
    treefmt-nix.url = "github:numtide/treefmt-nix?shallow=true";
    systems.url = "github:nix-systems/default?shallow=true";

    # Services & Applications
    home-manager.url = "github:nix-community/home-manager/nixos-unstable?shallow=true";
    nixvim.url = "github:nix-community/nixvim?shallow=true";
    nixarr.url = "github:rasmus-kirk/nixarr?shallow=true";
    authentik-nix.url = "github:nix-community/authentik-nix?shallow=true";
    vscode-server.url = "github:nix-community/nixos-vscode-server?shallow=true";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules?shallow=true";
    nixos-needsreboot.url = "https://flakehub.com/f/thefossguy/nixos-needsreboot/*.tar.gz";
    nixos-generators.url = "github:nix-community/nixos-generators?shallow=true";
    linkwarden-pr.url = "github:NixOS/nixpkgs/f0809e9f3402644c0987842727cb1d3f93d2e4a6?shallow=true";

    # Hyprland & Wayland
    hyprland.url = "github:hyprwm/Hyprland?shallow=true";
    hypr-contrib.url = "github:hyprwm/contrib?shallow=true";
    hyprpicker.url = "github:hyprwm/hyprpicker?shallow=true";
    hyprlock.url = "github:hyprwm/hyprlock?shallow=true";
    waybar.url = "github:Alexays/Waybar?shallow=true";

    # Gaming
    nix-gaming.url = "github:fufexan/nix-gaming?shallow=true";
  };

  outputs =
    { flake-utils, ... }@inputs:
    let
      helpers = import ./flakeHelpers.nix inputs;
      inherit (helpers) mkMerge mkNixos;
    in
    mkMerge [
      (flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        in
        {
          packages.default = pkgs.mkShell {
            packages = [
              pkgs.just
              # Consider adding nixos-rebuild-ng if you use it
            ];
          };
        }
      ))
      (mkNixos "homeserver" inputs.nixpkgs [
        ./hosts/homeserver
        ./modules/users/zeev
        ./modules/disko
        inputs.nixarr.nixosModules.default
        inputs.authentik-nix.nixosModules.default
        inputs.vscode-server.nixosModules.default
      ])
    ];
}