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
    nix-pia-vpn.url = "github:rcambrj/nix-pia-vpn";
  };

  outputs = { self, nixpkgs, disko, sops-nix, home-manager, nix-index-database, vscode-server, nix4nvchad, nix-pia-vpn, ... }@inputs: {
    nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      
      modules = [
        # External modules
        vscode-server.nixosModules.default
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        nix-index-database.nixosModules.nix-index
        nix-pia-vpn.nixosModules.default

        # Core system configuration
        ./configuration.nix
        ./hardware-configuration.nix
        ./disko.nix
        ./networking.nix
        ./modules/base.nix

        # Security services
        ./services/fail2ban.nix
        ./services/yubikey.nix

        # Infrastructure services
        ./services/database.nix
        ./services/caddy.nix
        ./services/homepage.nix
        ./services/tailscale.nix
        ./services/cloudflared.nix
        ./services/mosquitto.nix
        ./services/monitoring.nix

        # Media services
        ./services/jellyfin.nix
        ./services/audiobookshelf.nix
        ./services/media-content.nix
        ./services/transmission.nix

        # Productivity & Personal services
        ./services/nextcloud.nix
        ./services/microbin.nix
        ./services/paperless.nix
        ./services/radicale.nix
        ./services/samba.nix

        # Smart home & notifications
        ./services/home-assistant.nix
        ./services/keycloak.nix
        ./services/tg-notify.nix
      ];
    }; 
  };
}