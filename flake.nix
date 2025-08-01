{
  description = "NixOS configuration for homeserver";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    linkwarden.url = "github:EricTheMagician/nixpkgs/linkwarden";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";

    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

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
    nixarr = {
      url = "github:rasmus-kirk/nixarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim.url = "github:nix-community/nixvim";

    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    authentik-nix = {
      url = "github:nix-community/authentik-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-lib = {
      url = "github:snowfallorg/lib";
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
      nix-ld,
      authentik-nix,
      ...
    }@inputs:
    {
      nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; }; # This is used inside the modules themselves
        modules = [
          vscode-server.nixosModules.default
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          nix-index-database.nixosModules.nix-index
          nixarr.nixosModules.default
          nix-ld.nixosModules.nix-ld
          inputs.authentik-nix.nixosModules.default

          # Core system configuration files
          ./configuration.nix
          ./hardware-configuration.nix

          # Core system configuration
          # ./modules/isko
          ./modules/users
          ./modules/base
          ./modules/sops
          ./modules/monitoring
          ./modules/containers
          ./modules/backup
          ./modules/email
          ./modules/database/postgresql
          ./modules/security/authentik.nix
          ./modules/security/fail2ban.nix
          ./modules/network/base.nix
          ./modules/network/acme.nix
          ./modules/network/nginx.nix
          ./modules/network/tailscale.nix
          ./modules/network/cloudflared.nix

          # Services
          ./modules/services/yubikey.nix
          ./modules/services/homepage.nix
          ./modules/services/tailscale.nix
          ./modules/services/cloudflared.nix
          ./modules/services/miniflux.nix
          ./modules/services/microbin.nix
          ./modules/services/paperless.nix
          ./modules/services/radicale.nix
          ./modules/services/samba.nix
          ./modules/services/home-assistant.nix
          ./modules/services/nixarr.nix
          ./modules/services/kavita.nix
          ./modules/services/calibre-web.nix


          
          ./backup
        ];
      };
    };

  
  {
      sops.defaultSopsFile = "/var/lib/sops/age.key";

  }
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://4rmcyt.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "4rmcyt.cachix.org-1:uKI766iybXD8uDBVexbc5BCYAfdBJ262ID4C+dl2hws="
    ];
  };
}
