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
    inputs.nix-index-database.nixosModules.nix-index
    inputs.nixos-facter-modules.nixosModules.facter
    inputs.agenix.nixosModules.default
    {
      nixpkgs.config.allowUnfree = true;
      sops.age.keyFile = inputs.nixpkgs.lib.mkDefault "/root/.config/sops/age/keys.txt";
    }
  ];

  # Conditionally add disko only for non-WSL hosts
  commonModulesWithDisko = hostname:
    if (inputs.nixpkgs.lib.strings.hasInfix "wsl" (inputs.nixpkgs.lib.strings.toLower hostname))
    then commonModules
    else commonModules ++ [inputs.disko.nixosModules.disko];

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
            ({config, lib, ...}: {
              config.facter.reportPath = 
                if (lib.strings.hasInfix "wsl" (lib.strings.toLower config.networking.hostName))
                then null
                else ./hosts/nixos/${config.networking.hostName}/facter.json;
            })
          ]
          ++ (commonModulesWithDisko config.networking.hostName or "");
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