{
  description = "A highly structured NixOS configuration";
  nixConfig = {
    extra-substituters = [
      "https://aseipp-nix-cache.freetls.fastly.net"
      "https://nix-community.cachix.org"
      "https://nix-gaming.cachix.org"
      "https://homeserver.cachix.org"
      "https://chaotic-nyx.cachix.org"
      "https://4rmcyt.cachix.org"
    ];

    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "homeserver.cachix.org-1:0vStm6koDUwET/iWYhbKpsuVO4v3UgN3510zYH9YpZU="
      "4rmcyt.cachix.org-1:IzZEPOd8aKavFKw3BuUBAI/T93XUUWoS/n2M+LG65/0="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    
    # nixpkgs-cuda = {
    #   url = "github:NixOS/nixpkgs/nixos-unstable";
    #   config.cudaSupport = true;
    #   config.allowUnfree = true;
    # };

    # lix = {
    #   url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
    #   flake = false;
    # };

    # lix-module = {
    #   url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   inputs.lix.follows = "lix";
    # };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
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
    # nixpkgs-firefox-darwin.url = "github:bandithedoge/nixpkgs-firefox-darwin";
    nixarr.url = "github:rasmus-kirk/nixarr";
    authentik-nix.url = "github:nix-community/authentik-nix";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    nixos-generators.url = "github:nix-community/nixos-generators";

    nix-gaming.url = "github:fufexan/nix-gaming";
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
          # "aarch64-darwin"
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
            inherit (helpers) mkNixos;
          in
          {
            nixosConfigurations = {
              homeserver = mkNixos "homeserver" "x86_64-linux" [
                ./hosts/nixos/homeserver
                ./modules/users/zeev
                ./modules/disko/homeserver
                inputs.nixarr.nixosModules.default
                inputs.authentik-nix.nixosModules.default
                inputs.vscode-server.nixosModules.default
                {
                  sops.age.keyFile = "/var/lib/sops/age.key";
                  home-manager.users.zeev = {
                    imports = [
                      ./modules/home-manager/homeserver
                      inputs.sops-nix.homeManagerModules.sops
                      inputs.chaotic.homeManagerModules.default
                    ];
                    sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
                  };
                }
              ];

              desktop = mkNixos "desktop" "x86_64-linux" [
                ./hosts/nixos/desktop
                ./modules/users/zeev
                ./modules/disko/desktop
                # inputs.nixos-facter-modules.nixosModules.facter
                inputs.nix-gaming.nixosModules.pipewireLowLatency
                inputs.nix-gaming.nixosModules.platformOptimizations
                {
                  # config.facter.reportPath = ./hosts/nixos/desktop/facter.json;
                  sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
                  home-manager.users.zeev = {
                    imports = [
                      ./modules/home-manager/desktop
                      inputs.chaotic.homeManagerModules.default
                      inputs.sops-nix.homeManagerModules.sops
                    ];
                    sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
                  };
                }
              ];

              wsl = mkNixos "wsl" "x86_64-linux" [
                ./hosts/nixos/wsl
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
          };
      };
}
