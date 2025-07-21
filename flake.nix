{
  description = "NixOS configuration for homeserver";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
    nvchad4nix = {
      url = "github:MOIS3Y/nvchad4nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixarr = {
      url = "github:rasmus-kirk/nixarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      sops-nix,
      home-manager,
      nix-index-database,
      vscode-server,
      nixarr,
      nix4nvchad,
      ...
    }@inputs:
    {
      nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; }; # This is used inside the modules themselves
        modules = [
          # External modules are referred to directly by their argument name
          vscode-server.nixosModules.default
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          nix-index-database.nixosModules.nix-index
          nixarr.nixosModules.default

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.zeev = import ./.home-manager/default.nix {
                inherit inputs config;
                pkgs = inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
              };
            };
          }

          # Core system configuration files
          ./configuration.nix
          ./hardware-configuration.nix

          # Core system configuration
          # ./disko
          ./networking
          ./users
          ./modules/base
          ./modules/sops

          # Services
          ./services/fail2ban.nix
          ./services/yubikey.nix
          ./services/database.nix
          ./services/homepage.nix
          ./services/tailscale.nix
          ./services/cloudflared.nix
          ./services/monitoring.nix
          ./services/miniflux.nix
          ./services/nextcloud.nix
          ./services/microbin.nix
          ./services/paperless.nix
          ./services/radicale.nix
          ./services/samba.nix
          ./services/home-assistant.nix
          ./services/keycloak.nix
          ./services/nixarr.nix

          ./scripts/wg-sync.nix

          ./services/containers.nix
        ];
      };
    };
}
