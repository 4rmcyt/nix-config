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
        "https://4rmcyt-desktop.cachix.org?priority=0"
      ];
      extra-trusted-public-keys = [
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "4rmcyt-desktop.cachix.org-1:1lj75JVwUuiYqVzG/o2kuUneXV5ydrkFBLuY9b7Nvus="
      ];
    };

    programs.hyprland.enable = true;
    # Upstream version skew (as of 2026-08-04): Hyprland's CMakeLists.txt
    # requires `find_package(glaze 7...<8 QUIET)`, but nixpkgs' `glaze` has
    # moved to 8.0.0 — outside that range — so the Config-mode lookup
    # legitimately fails and CMake falls back to a network FetchContent
    # clone, which always fails in the sandbox. Pin glaze to the last 7.x
    # release (keeping the flake's own SSL/interop-disabled overlay tweaks)
    # until Hyprland bumps its own requirement to accept glaze 8.
    programs.hyprland.package = let
      glaze7 =
        (pkgs.glaze.override {
          enableSSL = false;
          enableInterop = false;
        }).overrideAttrs (_old: rec {
          version = "7.9.1";
          src = pkgs.fetchFromGitHub {
            owner = "stephenberry";
            repo = "glaze";
            tag = "v${version}";
            hash = "sha256-NRRq5MGF2f5PW0teYnq58ELzson+U6KHVPaY6r30KLA=";
          };
        });
    in
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland.override {
        glaze-hyprland = glaze7;
        # Upstream version skew (as of 2026-08-11): Hyprland's flake.lock pins
        # hyprland-guiutils (a16ad89, 2026-07-20) and hyprtoolkit (bdba25c,
        # 2026-06-27) out of lockstep, so hyprland-guiutils fails to link
        # against the older hyprtoolkit's undefined symbols. Since
        # hyprland-guiutils is only referenced inside `postInstall`'s
        # `wrapRuntimeDeps` PATH wrapping (lib.optionalString, lazily
        # unevaluated when false), disabling it drops the build dependency
        # entirely. Costs the hyprland-welcome/hyprland-run/hyprland-donate-screen
        # helper binaries on PATH until upstream re-syncs the pins.
        wrapRuntimeDeps = false;
      };
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
