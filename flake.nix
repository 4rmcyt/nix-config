{
  description = "A highly structured NixOS configuration";

  inputs = {
    # Core inputs
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    agenix.url = "github:ryantm/agenix";

    # Security & secrets
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
                inputs.agenix.nixosModules.default
                { config.facter.reportPath = ./hosts/nixos/homeserver/facter.json; }
                {
                  sops.age.keyFile = "/var/lib/sops/age.key";
                  home-manager = {
                    useGlobalPkgs = true;
                    useUserPackages = true;
                    backupFileExtension = "backup";
                    users.zeev = {
                      imports = [
                        ./modules/home-manager/homeserver
                        inputs.sops-nix.homeManagerModules.sops
                        inputs.agenix.homeManagerModules.default
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
                inputs.agenix.nixosModules.default
                inputs.nix-gaming.nixosModules.pipewireLowLatency
                inputs.nix-gaming.nixosModules.platformOptimizations
                inputs.lanzaboote.nixosModules.lanzaboote
                {
                  nixpkgs.config = {
                    allowUnfree = true;
                    permittedInsecurePackages = [
                      "qtwebengine-5.15.19"
                    ];
                  };

                  sops.age.keyFile = "/root/.config/sops/age/keys.txt";
                  home-manager = {
                    useGlobalPkgs = false;
                    useUserPackages = true;
                    backupFileExtension = "backup";
                    users.zeev = {
                      imports = [
                        ./modules/home-manager/desktop
                        inputs.sops-nix.homeManagerModules.sops
                        inputs.agenix.homeManagerModules.default
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
                inputs.nixos-wsl.nixosModules.wsl
                inputs.agenix.nixosModules.default
                {
                  sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
                  home-manager = {
                    useGlobalPkgs = true;
                    useUserPackages = true;
                    backupFileExtension = "backup"; # Add consistent backup extension
                    users.zeev = {
                      imports = [
                        ./modules/home-manager/wsl
                        inputs.sops-nix.homeManagerModules.sops
                        inputs.agenix.homeManagerModules.default
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
