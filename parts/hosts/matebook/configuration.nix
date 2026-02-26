# Matebook host definition via Dendritic configurations.nixos option.
{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner;
  nixosBase = config.modules.nixos.base;
in {
  configurations.nixos.matebook.module = { ...}: {
    imports = [
      nixosBase
      ../../../hosts/nixos/matebook
      inputs.flatpaks.nixosModules.default
      inputs.niri-flake.nixosModules.niri
      inputs.dms.nixosModules.dank-material-shell
    ];

    # Disable niri-flake's polkit agent (DMS provides its own)
    systemd.user.services.niri-flake-polkit.enable = false;

    # Facter
    facter.reportPath = ../../../hosts/nixos/matebook/facter.json;

    # Host-specific HM imports
    home-manager.users.${owner.username}.imports = [
      ../../../home/matebook
      inputs.betterfox-nix.homeModules.betterfox
      inputs.dms.homeModules.dank-material-shell
      inputs.dms.homeModules.niri
    ];
  };
}
