{
  inputs,
  userName,
}: let
  commonArgs = {
    system = "x86_64-linux";
    specialArgs = {inherit inputs;};
  };

  globalHomeManagerOptions = {
    useGlobalPkgs = false;
    useUserPackages = true;
    backupFileExtension = "backup";
  };

  userSpecificHomeManagerOptions = {
    nixpkgs.config.allowUnfree = true;
    sops.age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";
  };

  commonModules = [
    inputs.sops-nix.nixosModules.sops
    inputs.home-manager.nixosModules.home-manager
    inputs.disko.nixosModules.disko
    inputs.nix-index-database.nixosModules.nix-index
    inputs.nixos-facter-modules.nixosModules.facter
    inputs.agenix.nixosModules.default
    {
      nixpkgs.config.allowUnfree = true;
      sops.age.keyFile = inputs.nixpkgs.lib.mkDefault "/root/.config/sops/age/keys.txt";
    }
  ];

  commonHomeManagerModules = [
    inputs.sops-nix.homeManagerModules.sops
    inputs.agenix.homeManagerModules.default
  ];
in {
  mkHost = {modules}:
    inputs.nixpkgs.lib.nixosSystem (commonArgs
      // {
        modules =
          modules
          ++ [
            ({config, ...}: {
              config.facter.reportPath = ./hosts/nixos/${config.networking.hostName}/facter.json;
            })
          ]
          ++ commonModules;
      });

  mkHome = {modules}: [
    ./modules/users/${userName} 
    {
      home-manager =
        globalHomeManagerOptions
        // {
          extraSpecialArgs = {inherit inputs;};
          users.${userName} =
            userSpecificHomeManagerOptions
            // {
              imports = modules ++ commonHomeManagerModules;
            };
        };
    }
  ];

  mkStandaloneHome = {
    pkgs,
    modules,
  }:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {inherit inputs;};
      modules =
        [
          {
            nixpkgs.config.allowUnfree = true;
            sops.age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";
          }
        ]
        ++ modules
        ++ commonHomeManagerModules;
    };
}