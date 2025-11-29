{inputs}: {
  # NixOS system configurations
  nixos = {
    desktop = {
      hostModules = [
        ./hosts/nixos/desktop
        ./modules/disko/desktop
        inputs.disko.nixosModules.disko
        inputs.nix-gaming.nixosModules.pipewireLowLatency
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.flatpaks.nixosModules.default
        inputs.chaotic.nixosModules.nyx-cache
        inputs.chaotic.nixosModules.nyx-overlay
        inputs.lix-module.nixosModules.default
      ];
      homeModules = [
        ./home-manager/desktop
        inputs.plasma-manager.homeModules.plasma-manager
        inputs.betterfox-nix.homeModules.betterfox
        inputs.cosmic-manager.homeManagerModules.default
      ];
    };

    homeserver = {
      hostModules = [
        ./hosts/nixos/homeserver
        ./modules/disko/homeserver
        inputs.disko.nixosModules.disko
        inputs.nixarr.nixosModules.default
        inputs.authentik-nix.nixosModules.default
        inputs.vscode-server.nixosModules.default
        inputs.lix-module.nixosModules.default
      ];
      homeModules = [./home-manager/homeserver];
    };

    wsl = {
      hostModules = [
        ./hosts/nixos/wsl
        inputs.nixos-wsl.nixosModules.wsl
        inputs.lix-module.nixosModules.default
        inputs.vscode-server.nixosModules.default
      ];
      homeModules = [./home-manager/wsl];
    };

    matebook = {
      hostModules = [
        ./hosts/nixos/matebook
        ./modules/disko/matebook
        inputs.disko.nixosModules.disko
        inputs.flatpaks.nixosModules.default
        inputs.lix-module.nixosModules.default
      ];
      homeModules = [
        ./home-manager/matebook
        inputs.betterfox-nix.homeModules.betterfox
      ];
    };
  };

  # Installer ISO configurations
  installers = {
    desktop = {
      system = "x86_64-linux";
      modules = [
        ./hosts/installer/desktop
        inputs.flatpaks.nixosModules.default
        inputs.sops-nix.nixosModules.sops
        inputs.disko.nixosModules.disko
        inputs.chaotic.nixosModules.nyx-cache
        inputs.chaotic.nixosModules.nyx-overlay
      ];
    };

    homeserver = {
      system = "x86_64-linux";
      modules = [
        ./hosts/installer/homeserver
        inputs.sops-nix.nixosModules.sops
        inputs.disko.nixosModules.disko
      ];
    };

    matebook = {
      system = "x86_64-linux";
      modules = [
        ./hosts/installer/matebook
        inputs.sops-nix.nixosModules.sops
        inputs.disko.nixosModules.disko
      ];
    };
  };

  # Home manager standalone configurations
  home = {
    desktop = [
      ./home-manager/desktop
      inputs.plasma-manager.homeModules.plasma-manager
      inputs.cosmic-manager.homeManagerModules.cosmic-manager
      inputs.betterfox-nix.homeModules.betterfox
    ];
    homeserver = [./home-manager/homeserver];
    wsl = [./home-manager/wsl];
    matebook = [
      ./home-manager/matebook
      inputs.betterfox-nix.homeModules.betterfox
    ];
  };
}
