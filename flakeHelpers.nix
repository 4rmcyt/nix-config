{
  inputs,
  userName,
}: let
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

  commonHomeUserArgs = {
    extraSpecialArgs = {inherit inputs;};
    nixpkgs.config.allowUnfree = true;
    useGlobalPkgs = false;
    useUserPackages = true;
    backupFileExtension = "backup";
    sops.age.keyFile = "/home/${userName}/.config/sops/age/keys.txt";
  };
in {
  mkHost = {
    modules,
    hostName,
  }:
    inputs.nixpkgs.lib.nixosSystem (commonNixosArgs
      // {
        modules =
          modules
          ++ [{config.facter.reportPath = ./hosts/nixos/${hostName}/facter.json;}]
          ++ commonModules;
      });

  mkHome = {
    user,
    modules,
  }: {
    home-manager.users.${user} =
      commonHomeUserArgs
      // {
        imports = modules ++ commonHomeManagerModules;
      };
  };

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
