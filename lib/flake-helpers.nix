self: lib: let
  inherit (self) inputs;
  userName = "zeev";
in {
  # Generate NixOS configurations from host specs
  makeNixosConfigurations = hosts:
    lib.mapAttrs (_name: cfg:
      lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules =
          cfg.hostModules
          ++ [
            inputs.sops-nix.nixosModules.sops
            inputs.home-manager.nixosModules.home-manager
            inputs.nix-index-database.nixosModules.nix-index
            inputs.nixos-facter-modules.nixosModules.facter
            inputs.agenix.nixosModules.default
            {
              nixpkgs.config.allowUnfree = true;
              sops.age.keyFile = lib.mkDefault "/root/.config/sops/age/keys.txt";
            }
            ({
              config,
              lib,
              ...
            }: {
              facter.reportPath =
                lib.mkIf
                (!lib.strings.hasInfix "wsl" (lib.strings.toLower config.networking.hostName))
                (lib.mkDefault ../hosts/nixos/${config.networking.hostName}/facter.json);
            })
            ../modules/users/${userName}
            {
              home-manager = {
                useGlobalPkgs = false;
                useUserPackages = true;
                backupFileExtension = "backup";
                sharedModules = [{home.enableNixpkgsReleaseCheck = false;}];
                extraSpecialArgs = {inherit inputs;};
                users.${userName} = {
                  nixpkgs.config.allowUnfree = true;
                  sops.age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";
                  imports =
                    cfg.homeModules
                    ++ [
                      inputs.sops-nix.homeManagerModules.sops
                      inputs.agenix.homeManagerModules.default
                    ];
                };
              };
            }
          ];
      })
    hosts;

  # Generate installer configurations
  makeInstallers = installers:
    lib.mapAttrs (_name: cfg:
      lib.nixosSystem {
        inherit (cfg) system;
        specialArgs = {inherit inputs;};
        modules = cfg.modules ++ [{nixpkgs.config.allowUnfree = true;}];
      })
    installers;

  # Generate home-manager configurations for all systems
  makeHomeConfigurations = {
    configs,
    systems,
  }:
    lib.foldl' (acc: system:
      acc
      // (lib.mapAttrs' (name: modules:
        lib.nameValuePair "${userName}@${name}" (
          inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = inputs.nixpkgs.legacyPackages.${system};
            extraSpecialArgs = {inherit inputs;};
            modules =
              [
                {
                  nixpkgs.config.allowUnfree = true;
                  sops.age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";
                }
              ]
              ++ modules
              ++ [
                inputs.sops-nix.homeManagerModules.sops
                inputs.agenix.homeManagerModules.default
              ];
          }
        ))
      configs)) {}
    systems;
}
