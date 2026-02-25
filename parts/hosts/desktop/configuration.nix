# Desktop host definition via Dendritic configurations.nixos option.
{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner;
  nixosBase = config.modules.nixos.base;
in {
  configurations.nixos.desktop.module = {pkgs, ...}: {
    imports = [
      nixosBase
      ../../../hosts/nixos/desktop
      inputs.flatpaks.nixosModules.default
      inputs.nix-gaming.nixosModules.pipewireLowLatency
      inputs.dms.nixosModules.dank-material-shell
      inputs.dms.nixosModules.greeter
      inputs.niri-flake.nixosModules.niri
    ];

    # Niri via niri-flake NixOS module (uses nixpkgs niri 25.11, not niri-flake's stable)
    programs.niri.enable = true;
    programs.niri.package = pkgs.niri;

    # Disable niri-flake's polkit agent (DMS provides its own)
    systemd.user.services.niri-flake-polkit.enable = false;

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
      inputs.dms.homeModules.niri
    ];
  };
}
