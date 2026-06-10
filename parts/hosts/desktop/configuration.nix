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
      inputs.niri-flake.nixosModules.niri
      inputs.nirinit.nixosModules.nirinit
      inputs.noctalia.nixosModules.default
      ../../../modules/nix/lix
    ];

    services.nirinit.enable = true;

    # Niri via niri-flake NixOS module (uses nixpkgs niri 25.11, not niri-flake's stable)
    programs.niri.enable = true;
    programs.niri.package = pkgs.niri;

    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.writeShellScript "niri-session" ''
          exec ${pkgs.niri}/bin/niri --session >> "$HOME/.local/state/niri/niri.log" 2>&1
        ''}";
        user = owner.username;
      };
    };

    # Facter
    facter.reportPath = ../../../hosts/nixos/desktop/facter.json;

    # Host-specific HM imports
    home-manager.users.${owner.username}.imports = [
      ../../../home/desktop
      inputs.stylix.homeModules.stylix
      # inputs.pam-shim.homeModules.default
      inputs.noctalia.homeModules.default
    ];
  };
}
