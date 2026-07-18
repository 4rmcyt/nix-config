# Desktop host definition via Dendritic configurations.nixos option.
{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner;
  nixosBase = config.modules.nixos.base;
  nixosHm = config.modules.nixos.hm;
  nixosWorkstation = config.modules.nixos.workstation;
in {
  configurations.nixos.desktop.module = {pkgs, ...}: {
    imports = [
      nixosBase
      nixosHm
      nixosWorkstation
      ../../../hosts/nixos/desktop
      inputs.noctalia.nixosModules.default
      ../../../modules/nix/lix
    ];

    nix.settings = {
      extra-substituters = [
        "https://cache.nixos-cuda.org?priority=1"
        "https://cuda-maintainers.cachix.org?priority=1"
        "https://hyprland.cachix.org"
      ];
      extra-trusted-public-keys = [
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };

    programs.hyprland.enable = true;
    programs.hyprland.package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    programs.hyprland.portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    programs.hyprland.withUWSM = true;

    # greetd has no session picker (direct exec), so invoke uwsm ourselves —
    # this is the exact command nixpkgs' hyprland package embeds in its own
    # generated hyprland-uwsm.desktop (share/wayland-sessions/), just run
    # directly instead of through a display manager's session list.
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.writeShellScript "hyprland-session" ''
          exec ${pkgs.uwsm}/bin/uwsm start -e -D Hyprland hyprland.desktop
        ''}";
        user = owner.username;
      };
    };

    # Facter
    facter.reportPath = ../../../hosts/nixos/desktop/facter.json;

    # Host-specific HM imports
    home-manager.users.${owner.username} = {
      nixpkgs.config.permittedInsecurePackages = ["pnpm-10.29.2" "electron-40.10.5"];
      imports = [
        ../../../home/desktop
        # inputs.stylix.homeModules.stylix
        # inputs.pam-shim.homeModules.default
        inputs.noctalia.homeModules.default
      ];
    };
  };
}
