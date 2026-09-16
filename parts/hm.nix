{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner;
in {
  modules.nixos.hm = {
    imports = [
      inputs.home-manager.nixosModules.home-manager
    ];

    home-manager = {
      useGlobalPkgs = false;
      useUserPackages = true;
      backupFileExtension = "hm-backup";
      sharedModules = [
        {home.enableNixpkgsReleaseCheck = false;}
        {
          # home-manager's own modules/programs/noctalia.nix conflicts with
          # inputs.noctalia.homeModules.default's nix/home-module.nix.
          disabledModules = ["programs/noctalia.nix"];
        }
      ];
      extraSpecialArgs = {inherit inputs;};

      users.${owner.username} = {
        imports = [
          config.modules.homeManager.base
        ];
      };
    };
  };
}
