# File: nixos-config/flakeHelpers.nix  
inputs:
let
  helpers = {
    mkNixos =
      machineHostname: system: extraModules:
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          host = machineHostname;
        };
        modules = [
          inputs.sops-nix.nixosModules.sops
          inputs.home-manager.nixosModules.home-manager
          inputs.disko.nixosModules.disko
          inputs.nix-index-database.nixosModules.nix-index
          inputs.auto-cpufreq.nixosModules.default
          inputs.nixos-facter-modules.nixosModules.facter
          {
            facter.reportPath = ./facter.json;
          }
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.zeev = {
              imports = [
                inputs.sops-nix.homeManagerModules.sops
                inputs.mac-app-util.homeManagerModules.default
              ];
              sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
            };
          }
        ]
        ++ extraModules;
      };
    mkDarwin =
      machineHostname: system: extraModules:
      let
        darwinConfig = inputs.nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            host = machineHostname;
          };
          modules = [
            inputs.sops-nix.darwinModules.sops
            inputs.home-manager.darwinModules.home-manager
            inputs.mac-app-util.darwinModules.default
            inputs.nix-homebrew.darwinModules.nix-homebrew
            {
              home-manager.users.vk = {
                imports = [
                  {
                    nixpkgs.config.allowUnfree = true;
                  }
                  inputs.sops-nix.homeManagerModules.sops
                ];
                sops.age.keyFile = "/Users/vk/.config/sops/age/keys.txt";
              };
            }
          ]
          ++ extraModules;
        };
      in
      darwinConfig // { type = "darwin-configuration"; };
  };
in
helpers