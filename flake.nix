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
    nix4nvchad.url = "github:nix-community/nix4nvchad";
    nixarr = {
      url = "github:rasmus-kirk/nixarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

    outputs = { self, nixpkgs, ... }@inputs:
    let
      systemModules = [
        inputs.disko.nixosModules.disko
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
        inputs.nix-index-database.nixosModules.nix-index
        inputs.vscode-server.nixosModules.default
        inputs.nixarr.nixosModules.default
        inputs.nix4nvchad.nixosModules.default

        # Core system configuration files
        ./configuration.nix
        ./hardware-configuration.nix

        # Core system configuration
        ./disko
        ./networking
        ./users
        ./modules/base
        ./modules/sops
        ({ sops.defaultSopsFile = ./secrets/secrets.yaml; })
        
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

        ./services/containers.nix 
      ];
    in
    {
      nixConfig = {
        substituters = [
          "https://cache.nixos.org/"
          "https://nix-community.cachix.org"
          "https://nixarr.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9UfP3dIR2A7ahVhES3/x1V2S4G/P5t0hKprM4="
          "nixarr.cachix.org-1:HER9y2eS44D4T822z61t2u3Z6zY2S4T5f/Yg7R/86aA="
        ];
      };

      nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = systemModules;
      };

      packages.x86_64-linux.iso = inputs.nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        modules = systemModules; 
        format = "iso";
      };
    };
}    