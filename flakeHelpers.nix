{
  inputs,
  userName,
}: let
  hostConfig = hostName: "./hosts/nixos/${hostName}";
  diskConfig = hostName: "./modules/disko/${hostName}";
  homeConfig = hostName: "./home-manager/${hostName}";

  commonArgs = {
    system = "x86_64-linux";
    specialArgs = {inherit inputs;};
  };

  commonHomeUserArgs = {
    extraSpecialArgs = {inherit inputs;};
    nixpkgs.config.allowUnfree = true;
    useGlobalPkgs = false;
    useUserPackages = true;
    backupFileExtension = "backup";
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
      sops.age.keyFile = "/root/.config/sops/age/keys.txt";
    }
  ];

  commonHomeManagerModules = [
    inputs.sops-nix.homeManagerModules.sops
    inputs.agenix.homeManagerModules.default
  ];
  mkHomeModule = {
    user,
    modules,
  }: {
    home-manager.users.${user} =
      commonHomeUserArgs
      // {
        imports = modules ++ commonHomeManagerModules;
      };
  };
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
  mkHome = { modules }: [ 
    ./modules/users/${userName}
    (mkHomeModule {
      user = userName;
      modules = modules;
    })
  ];

  mkStandaloneHome = {
    pkgs,
    modules,
  }:
    inputs.home-manager.lib.homeManagerConfiguration (commonHomeUserArgs
      // {
        inherit pkgs;
        modules = modules ++ commonHomeManagerModules;
      });
}
