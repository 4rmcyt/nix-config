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
      inputs.niri-flake.nixosModules.niri
      inputs.nirinit.nixosModules.nirinit
      inputs.noctalia.nixosModules.default
      ../../../modules/nix/lix
    ];

    nix.settings = {
      extra-substituters = [
        "https://cache.nixos-cuda.org?priority=1"
        "https://cuda-maintainers.cachix.org?priority=1"
      ];
      extra-trusted-public-keys = [
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };

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

    nixpkgs.config.problems.handlers.zfs.broken = "warn";

    # Facter
    facter.reportPath = ../../../hosts/nixos/desktop/facter.json;

    # Host-specific HM imports
    home-manager.users.${owner.username} = {
      nixpkgs.config.permittedInsecurePackages = ["pnpm-10.29.2"];
      imports = [
        ../../../home/desktop
        # inputs.stylix.homeModules.stylix
        # inputs.pam-shim.homeModules.default
        inputs.noctalia.homeModules.default
      ];
    };
  };
}
