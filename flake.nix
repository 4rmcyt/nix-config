{
  description = "NixOS Homeserver Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, disko, nix-index-database, flake-utils, vscode-server, ... }@inputs:
  {
    nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      
      modules = [
        # Core configuration files - DO NOT INCLUDE ./home.nix HERE!
        ./configuration.nix
        ./disko.nix
        ./networking.nix
        
        # Centralized services
        ./services/database.nix      # NEW: Centralized database config
        ./services/nextdns.nix

        # Service modules
        ./services/audiobookshelf.nix
        ./services/caddy.nix
        ./services/cloudflared.nix
        ./services/deluge-vpn.nix
        ./services/fail2ban.nix
        ./services/home-assistant.nix
        ./services/homepage.nix
        ./services/jellyfin.nix
        ./services/keycloak.nix
        ./services/media-content.nix
        ./services/microbin.nix              
        ./services/nextcloud.nix
        ./services/paperless.nix
        ./services/radicale.nix
        ./services/samba.nix
        ./services/tailscale.nix
        ./services/tg-notify.nix
        ./services/yubikey.nix
        
        # Scripts
        ./scripts/keycloak-yubikey-setup.nix
        
        # Enable modules from flake inputs
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        nix-index-database.nixosModules.nix-index
        vscode-server.nixosModules.default
      ];
    };
  };
}