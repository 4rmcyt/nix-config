# Wires home-manager into NixOS as a module.
# Imports HM NixOS module, configures shared settings,
# and imports homeManager.base for the owner user.
{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner;
in {
  modules.nixos.base = {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
      inputs.agenix.nixosModules.default
      inputs.nix-index-database.nixosModules.nix-index
      inputs.nixos-facter-modules.nixosModules.facter
      inputs.vscode-server.nixosModules.default
      inputs.ucodenix.nixosModules.default
      inputs.disko.nixosModules.disko
      inputs.nixos-jellyfin.nixosModules.default
      inputs.nix-topology.nixosModules.default
    ];

    home-manager = {
      useGlobalPkgs = false;
      useUserPackages = true;
      backupFileExtension = "hm-backup";
      sharedModules = [{home.enableNixpkgsReleaseCheck = false;}];
      extraSpecialArgs = {inherit inputs;};

      users.${owner.username} = {
        imports = [
          config.modules.homeManager.base
        ];
      };
    };
  };
}
