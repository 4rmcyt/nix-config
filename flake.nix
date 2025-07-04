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
        
        ./services/fail2ban.nix
        ./services/database.nix    # PostgreSQL (needed by many services)
        ./services/caddy.nix       # Reverse proxy
        ./services/homepage.nix    # Dashboard
        ./services/jellyfin.nix    # Media server
        
        ./services/nextcloud.nix
        ./services/tailscale.nix
        ./services/microbin.nix
        
        ./services/keycloak.nix
        ./services/home-assistant.nix
        ./services/deluge-vpn.nix
        ./services/audiobookshelf.nix

        ./services/cloudflared.nix
        ./services/media-content.nix
        ./services/paperless.nix
        ./services/radicale.nix
        # ./services/nextdns.nix
        ./services/samba.nix
        ./services/tg-notify.nix
        ./services/yubikey.nix
        
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
