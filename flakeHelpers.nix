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
          {
            nixpkgs.overlays = [
              (final: prev: 
                let 
                  stable = import inputs.nixpkgs-stable { 
                    inherit system; 
                    config.allowUnfree = true; 
                  };
                in {
                  docutils = stable.docutils;
                  
                  python3Packages = prev.python3Packages // {
                    docutils = stable.python3Packages.docutils;
                    nltk = prev.python3Packages.nltk.overrideAttrs (oldAttrs: {
                      passthru = (oldAttrs.passthru or {}) // {
                        data = stable.python3Packages.nltk.data or null;
                      };
                    });
                  };
                })
            ];
          }
          inputs.sops-nix.nixosModules.sops
          {
            sops.age.keyFile = "/var/lib/sops/age.key";
          }
          inputs.home-manager.nixosModules.home-manager
          inputs.disko.nixosModules.disko
          inputs.nix-index-database.nixosModules.nix-index
          inputs.auto-cpufreq.nixosModules.default
          inputs.nixos-facter-modules.nixosModules.facter
          {
            facter.reportPath = ./facter.json;
          }
          {
            home-manager.users.zeev = {
              imports = [
                ./modules/home-manager/homeserver
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
            # Import the sops-nix darwin module
            inputs.sops-nix.darwinModules.sops
            inputs.home-manager.darwinModules.home-manager
            inputs.mac-app-util.darwinModules.default
            inputs.nix-homebrew.darwinModules.nix-homebrew
            {
              # It's good practice to specify the system key file here

              home-manager.users.vk = {
                imports = [
                  ./modules/home-manager/macbook
                  {
                    nixpkgs.config.allowUnfree = true;
                  }
                  inputs.sops-nix.homeManagerModules.sops
                ];
                sops.age.keyFile = "/Users/vk/.config/sops/age/keys.txt"; # Adjusted path for vk
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
