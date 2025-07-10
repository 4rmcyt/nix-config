{
  description = "NixOS configuration for homeserver";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

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

    nixarr.url = "github:rasmus-kirk/nixarr";
  };

  outputs = { self, nixpkgs, disko, sops-nix, home-manager, nix-index-database, vscode-server, nix4nvchad, ... }@inputs:
  let
    specialArgs = {inherit inputs;};
      system = "x86_64-linux";
      pkgs-unstable = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-25-05 = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      lib = nixpkgs.lib;
  in
  {
    nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
      modules = [
        # External modules
        inputs.vscode-server.nixosModules.default
        inputs.disko.nixosModules.disko
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
        inputs.nix-index-database.nixosModules.nix-index
        inputs.nixarr.nixosModules.default

        # Core system configuration
        ./configuration.nix
        ./hardware-configuration.nix
        ./disko.nix
        ./networking.nix
        ./modules/base.nix

        # Services
        ./services/fail2ban.nix
        ./services/yubikey.nix
        ./services/database.nix
        ./services/homepage.nix
        ./services/tailscale.nix
        ./services/cloudflared.nix
        ./services/monitoring.nix
        ./services/jellyfin.nix
        ./services/audiobookshelf.nix
        ./services/miniflux.nix
        ./services/nextcloud.nix
        ./services/microbin.nix
        ./services/paperless.nix
        ./services/radicale.nix
        ./services/samba.nix
        ./services/home-assistant.nix
        ./services/keycloak.nix
      ];
    };
  };
}

