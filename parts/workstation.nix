# Workstation-specific NixOS modules — desktop, laptop, homeserver.
# Not imported on headless appliances (gcp-relay).
{
  inputs,
  lib,
  ...
}: {
  # `pkgs` is a NixOS-module arg (supplied when this deferred module is
  # imported into a host), NOT a flake-parts top-level arg (that's only
  # injected inside `perSystem`) — so this has to be a function taking its
  # own {pkgs, ...}, not reach for the outer flake-parts scope's pkgs.
  modules.nixos.workstation = {
    config,
    pkgs,
    ...
  }: {
    imports = [
      inputs.nixos-facter-modules.nixosModules.facter
      inputs.ucodenix.nixosModules.default
    ];

    facter.reportPath = ../hosts/nixos + "/${config.networking.hostName}/facter.json";

    programs.gnupg.agent.enable = true;

    environment.systemPackages = with pkgs; [
      lixPackageSets.latest.nixpkgs-review
      lixPackageSets.latest.nix-eval-jobs
      lixPackageSets.latest.nix-fast-build
      lixPackageSets.latest.colmena
      lixPackageSets.latest.nix-direnv
      lixPackageSets.latest.nix-serve-ng
      lixPackageSets.latest.boehmgc
      lixPackageSets.latest.nil
      lixPackageSets.latest.nurl
      lixPackageSets.latest.nix-init
      lixPackageSets.latest.nix-update
    ];
  };

  # GUI workstation NixOS modules — desktop, matebook only. Not on homeserver
  # (no GUI) or gcp-relay (headless). nfs-client rides along here since only
  # the GUI workstations mount the homeserver NFS shares (homeserver is the
  # server, gcp-relay has no need).
  modules.nixos.workstationGui.imports = [
    ../modules/GUI/chrome
    ../modules/GUI/flatpak
    ../modules/GUI/kdeconnect
    ../modules/GUI/nemo
    ../modules/networking/nfs-client
  ];

  # GUI workstation Home Manager modules — desktop, matebook. Not imported
  # on homeserver (no GUI) or headless appliances.
  modules.homeManager.workstation = {
    imports = [
      ../modules/GUI/chrome/home.nix
      ../modules/GUI/firefox
      ../modules/GUI/terminal
      ../modules/GUI/mpv
      ../modules/GUI/nemo/home.nix
      ../modules/GUI/obsidian
      ../modules/TUI/common
      ../modules/TUI/helix
      ../modules/TUI/neovim
      ../modules/TUI/zsh
      ../modules/TUI/atuin
      ../modules/TUI/zellij
      ../modules/WM/noctalia.nix
      ../modules/WM/mime
      ../modules/dev
      ../modules/dev/git.nix
      ../modules/security/gpg.nix
    ];

    home.sessionVariables.BROWSER = lib.mkForce "firefox";
  };
}
