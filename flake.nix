{
  description = "NixOS configuration for homeserver";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    nix4nvchad.url = "github:nix-community/nix4nvchad";
  };

  outputs = { self, nixpkgs, disko, sops-nix, home-manager, nix-index-database, vscode-server, nix4nvchad, ... }@inputs: {
    nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      
      modules = [
        # Core configuration files
        ./configuration.nix
        ./disko.nix
        ./networking.nix
        
        # Centralized services
        ./services/database.nix
        ./services/nextdns.nix

        # Basic services (no secrets required)
        ./services/caddy.nix
        ./services/fail2ban.nix
        ./services/homepage.nix
        ./services/jellyfin.nix
        ./services/samba.nix
        
        # TEMPORARILY COMMENTED OUT - Services that require secrets
        # ./services/audiobookshelf.nix
        # ./services/cloudflared.nix
        # ./services/deluge-vpn.nix
        # ./services/home-assistant.nix
        # ./services/keycloak.nix
        # ./services/media-content.nix
        # ./services/microbin.nix              
        # ./services/nextcloud.nix
        # ./services/radicale.nix
        # ./services/tailscale.nix
        # ./services/tg-notify.nix
        # ./services/yubikey.nix
        
        # Scripts
        # ./scripts/keycloak-yubikey-setup.nix
        
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