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
          # inputs.lix-module.nixosModules.default
          {
            home-manager = {
              extraSpecialArgs = { inherit inputs; };
            };
          }
        ]
        ++ extraModules;
      };

    # mkDarwin =
    #   machineHostname: system: extraModules:
    #   let
    #     darwinConfig = inputs.nix-darwin.lib.darwinSystem {
    #       inherit system;
    #       specialArgs = {
    #         inherit inputs;
    #         host = machineHostname;
    #       };
    #       modules = [
    #         inputs.home-manager.darwinModules.home-manager
    #         inputs.mac-app-util.darwinModules.default
    #         {
    #           home-manager = {
    #             useGlobalPkgs = false;
    #             useUserPackages = true;
    #             extraSpecialArgs = { inherit inputs; };
    #           };
    #         }
    #       ]
    #       ++ extraModules;
    #     };
    #   in
    #   darwinConfig // { type = "darwin-configuration"; };
  };
in
helpers
