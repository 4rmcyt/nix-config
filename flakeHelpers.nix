inputs: {
  mkNixos = machineHostname: system: extraModules:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs;
        host = machineHostname;
      };
      modules = [
        inputs.sops-nix.nixosModules.sops
        { sops.age.keyFile = "/var/lib/sops/age.key"; }
        inputs.home-manager.nixosModules.home-manager
        inputs.disko.nixosModules.disko
        inputs.nix-index-database.nixosModules.nix-index
        inputs.auto-cpufreq.nixosModules.default
        "${inputs.linkwarden-pr}/nixos/modules/services/web-apps/linkwarden.nix"
        inputs.nixos-facter-modules.nixosModules.facter
        { facter.reportPath = ./facter.json; }
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.zeev = {
            imports = [
              ./modules/home-manager/${machineHostname}
              inputs.sops-nix.homeManagerModules.sops
            ];
            sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
          };
        }
      ] ++ extraModules;
    };

  mkDarwin = machineHostname: system: extraModules:
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        inherit inputs;
        host = machineHostname;
      };
      modules = [
        inputs.home-manager.darwinModules.home-manager
        inputs.mac-app-util.darwinModules.default
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.zeev = {
            imports = [
              ./modules/home-manager/${machineHostname}
              inputs.sops-nix.homeManagerModules.sops
              inputs.mac-app-util.homeManagerModules.default
            ];
            sops.age.keyFile = "/Users/zeev/.config/sops/age/keys.txt";
          };
        }
      ] ++ extraModules;
    };
}