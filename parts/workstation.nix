{
  inputs,
  lib,
  ...
}: {
  # `pkgs` here is a NixOS-module arg, not the flake-parts top-level one (only
  # injected inside `perSystem`) — needs its own {pkgs, ...}.
  modules.nixos.bareMetal = {
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

  # nfs-client rides along here since only the GUI workstations mount homeserver's NFS shares.
  modules.nixos.workstationGui.imports = [
    ../modules/GUI/chrome
    ../modules/GUI/flatpak
    ../modules/GUI/kdeconnect
    ../modules/GUI/nemo
    ../modules/networking/nfs-client
  ];

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
      ../modules/TUI/starship
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
