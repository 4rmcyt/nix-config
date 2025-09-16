{
  description = "A highly structured NixOS configuration";

  nixConfig = {
    extra-substituters = [
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
    # Core inputs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # NixOS modules
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Security & secrets
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Performance & hardware
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    auto-cpufreq = {
      url = "github:AdnanHodzic/auto-cpufreq";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-gaming.url = "github:fufexan/nix-gaming";

    # Services & applications
    nixarr.url = "github:rasmus-kirk/nixarr";
    authentik-nix.url = "github:nix-community/authentik-nix";
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # Development tools
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";

    # Non-flake inputs
    cpu-microcodes = {
      url = "github:platomav/CPUMicrocodes";
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
        systems = import inputs.systems;
        imports = [ treefmt-nix.flakeModule ];
        perSystem =
          { pkgs, ... }:
          {
            devShells.default = import ./devshell.nix { inherit pkgs; };
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
                inputs.nixos-facter-modules.nixosModules.facter
                { config.facter.reportPath = ./hosts/nixos/homeserver/facter.json; }
                {
                  sops.age.keyFile = "/var/lib/sops/age.key";
                  home-manager = {
                    useGlobalPkgs = true;
                    useUserPackages = true;
                    backupFileExtension = "hm-backup";
                    users.zeev = {
                      imports = [
                        ./modules/home-manager/homeserver
                        inputs.sops-nix.homeManagerModules.sops
                      ];
                      sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
                    };
                  };
                }
              ];

              desktop = mkNixos "desktop" "x86_64-linux" [
                ./hosts/nixos/desktop
                ./modules/users/zeev
                ./modules/disko/desktop
                inputs.nixos-facter-modules.nixosModules.facter
                { config.facter.reportPath = ./hosts/nixos/desktop/facter.json; }
                inputs.nix-gaming.nixosModules.pipewireLowLatency
                inputs.nix-gaming.nixosModules.platformOptimizations
                {
                  nixpkgs.config = {
                    allowUnfree = true;
                    permittedInsecurePackages = [
                      "qtwebengine-5.15.19"
                    ];
                  };

                  # config.facter.reportPath = ./hosts/nixos/desktop/facter.json;
                  sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
                  home-manager = {
                    useGlobalPkgs = false;
                    useUserPackages = true;
                    backupFileExtension = "hm-backup";
                    users.zeev = {
                      imports = [
                        ./modules/home-manager/desktop
                        inputs.chaotic.homeManagerModules.default
                        inputs.sops-nix.homeManagerModules.sops
                      ];
                      nixpkgs.config = {
                        allowUnfree = true;
                        permittedInsecurePackages = [
                          "qtwebengine-5.15.19"
                        ];
                      };
                      sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
                    };
                  };
                }
              ];

              wsl = mkNixos "wsl" "x86_64-linux" [
                ./hosts/nixos/wsl
                ./modules/users/zeev
                inputs.nixos-wsl.nixosModules.wsl # Add WSL module
                {
                  sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
                  home-manager = {
                    useGlobalPkgs = true;
                    useUserPackages = true;
                    backupFileExtension = "hm-backup"; # Add consistent backup extension
                    users.zeev = {
                      imports = [
                        ./modules/home-manager/wsl
                        inputs.sops-nix.homeManagerModules.sops
                      ];
                      sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt"; # Add sops key
                    };
                  };
                }
              ];
            };
          };
      };
}
