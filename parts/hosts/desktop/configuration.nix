# Desktop host definition via Dendritic configurations.nixos option.
{ config, inputs, ... }:
let
  owner = config.meta.owner;
  nixosBase = config.modules.nixos.base;
in
{
  configurations.nixos.desktop.module = { ... }: {
    imports = [
      nixosBase
      ../../../hosts/nixos/desktop
      inputs.flatpaks.nixosModules.default
      inputs.nix-gaming.nixosModules.pipewireLowLatency
      inputs.dms.nixosModules.dank-material-shell
      inputs.dms.nixosModules.greeter
    ];

    # Facter
    facter.reportPath = ../../../hosts/nixos/desktop/facter.json;

    # Host-specific HM imports
    home-manager.users.${owner.username}.imports = [
      ../../../home/desktop
      inputs.betterfox-nix.homeModules.betterfox
      inputs.plasma-manager.homeModules.plasma-manager
      inputs.stylix.homeModules.stylix
      inputs.pam-shim.homeModules.default
      inputs.dms.homeModules.dank-material-shell
    ];
  };
}
