# Home Manager NixOS integration — wired into modules.nixos.hm.
# Import this module on hosts that use Home Manager (desktop, matebook, homeserver).
# Headless appliances (gcp-relay) skip this entirely.
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
          # home-manager ships its own modules/programs/noctalia.nix, which
          # re-declares programs.noctalia.enable and conflicts with
          # inputs.noctalia.homeModules.default's nix/home-module.nix. Disable
          # the home-manager copy, mirroring what noctalia's own
          # nix/nixos-module.nix does for the NixOS-side module.
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
