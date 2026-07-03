# Home Manager NixOS integration — wired into modules.nixos.hm.
# Import this module on hosts that use Home Manager (desktop, matebook, homeserver, wsl).
# Headless appliances (router, gcp-relay) skip this entirely.
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
      inputs.sops-nix.nixosModules.sops
      inputs.nixos-facter-modules.nixosModules.facter
      inputs.disko.nixosModules.disko
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
