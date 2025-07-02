{
  description = "NixOS configuration for zeev's home server";

  inputs = {
    # The core package set for NixOS
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Disko for declarative disk partitioning
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # sops-nix for declarative, encrypted secrets management
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Home Manager for declarative user environment management
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko, sops-nix, home-manager, ... }@inputs: {
    nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      # Pass all flake inputs to the modules for easy access
      specialArgs = { inherit inputs; };

      modules = [
        # Core configuration files
        ./configuration.nix
        ./disko.nix
        ./networking.nix
        ./home.nix
        # Enable modules from flake inputs
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager

        # Service modules
        ./services/cloudflared.nix
        ./services/caddy.nix
        ./services/deluge-vpn.nix
        ./services/fail2ban.nix
        ./services/home-assistant.nix
        ./services/keycloak.nix
        ./services/yubikey.nix
        ./services/media-content.nix
        ./services/nextcloud.nix
        ./services/paperless.nix
        ./services/radicale.nix
        ./services/jellyfin.nix
        ./services/tailscale.nix
        ./services/tg-notify.nix
        
        # Scripts
        ./scripts/keycloak-yubikey-setup.nix
      ];
    };
  };
}