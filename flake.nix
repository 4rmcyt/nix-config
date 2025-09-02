{
  description = "A highly structured NixOS configuration";
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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nixpkgs-cuda = {
    #   url = "github:NixOS/nixpkgs/nixos-unstable";
    #   config.cudaSupport = true;
    #   config.allowUnfree = true;
    # };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    nixpkgs-firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin";
    nixarr.url = "github:rasmus-kirk/nixarr";
    authentik-nix.url = "github:nix-community/authentik-nix";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    nixos-generators.url = "github:nix-community/nixos-generators";
    linkwarden-pr = {
      url = "github:NixOS/nixpkgs/f0809e9f3402644c0987842727cb1d3f93d2e4a6?shallow=1";
      flake = false;
    };
    hyprland.url = "github:hyprwm/Hyprland";
    hypr-contrib.url = "github:hyprwm/contrib";
    hyprpicker.url = "github:hyprwm/hyprpicker";
    hyprlock.url = "github:hyprwm/hyprlock";
    waybar.url = "github:Alexays/Waybar";
    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs =
    inputs@{ treefmt-nix, ... }:
    inputs.flake-parts.lib.mkFlake
      {
        inherit inputs;
      }
      {
        systems = [
          "x86_64-linux"
          "aarch64-darwin"
        ];
        imports = [ treefmt-nix.flakeModule ];
        perSystem =
          { pkgs, ... }:
          {
            devShells.default = import ./devshell.nix {
              inherit pkgs;
            };
            treefmt = import ./treefmt.nix;
          };

        flake =
          let
            helpers = import ./flakeHelpers.nix inputs;
            inherit (helpers) mkNixos mkDarwin;
          in
          {
            nixosConfigurations = {
              homeserver = mkNixos "homeserver" "x86_64-linux" [
                ./hosts/nixos/homeserver
                ./modules/users/zeev
                ./modules/disko
                inputs.nixarr.nixosModules.default
                inputs.authentik-nix.nixosModules.default
                inputs.vscode-server.nixosModules.default
                inputs.chaotic.nixosModules.nyx-cache
                inputs.chaotic.nixosModules.nyx-overlay
                inputs.chaotic.nixosModules.nyx-registry
                {
                  sops.age.keyFile = "/var/lib/sops/age.key";
                  home-manager.users.zeev = {
                    imports = [
                      ./modules/home-manager/homeserver
                      inputs.sops-nix.homeManagerModules.sops
                    ];
                    sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
                  };
                }
              ];

              desktop = mkNixos "desktop" "x86_64-linux" [
                ./hosts/desktop
                ./modules/users/zeev
                inputs.chaotic.nixosModules.nyx-cache
                inputs.chaotic.nixosModules.nyx-overlay
                inputs.chaotic.nixosModules.nyx-registry
                {
                  sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
                  home-manager.users.zeev = {
                    imports = [
                      ./modules/home-manager/desktop
                      inputs.sops-nix.homeManagerModules.sops
                    ];
                    sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
                  };
                }
              ];

              wsl = mkNixos "wsl" "x86_64-linux" [
                ./hosts/wsl
                ./modules/users/zeev
                {
                  sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
                  home-manager.users.zeev = {
                    imports = [
                      ./modules/home-manager/wsl
                      inputs.sops-nix.homeManagerModules.sops
                    ];
                  };
                }
              ];
            };

            darwinConfigurations = {
              macbook = mkDarwin "macbook" "aarch64-darwin" [
                ./hosts/darwin/macbook
                ./modules/users/vk
                {
                  sops.age.keyFile = "/Users/vk/.config/sops/age/keys.txt";
                  home-manager.users.vk = {
                    imports = [
                      ./modules/home-manager/macbook
                      {
                        nixpkgs.config.allowUnfree = true;
                      }
                      inputs.sops-nix.homeManagerModules.sops
                    ];
                    sops.age.keyFile = "/Users/vk/.config/sops/age/keys.txt";
                  };
                }
              ];
            };
          };
      };
}
