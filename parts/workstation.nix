# Workstation-specific NixOS modules — desktop, laptop, homeserver.
# Not imported on headless appliances (router, gcp-relay).
{
  inputs,
  lib,
  ...
}: {
  # `pkgs` is a NixOS-module arg (supplied when this deferred module is
  # imported into a host), NOT a flake-parts top-level arg (that's only
  # injected inside `perSystem`) — so this has to be a function taking its
  # own {pkgs, ...}, not reach for the outer flake-parts scope's pkgs.
  modules.nixos.workstation = {pkgs, ...}: {
    imports = [
      inputs.nixos-facter-modules.nixosModules.facter
      inputs.ucodenix.nixosModules.default
    ];

    programs.gnupg.agent.enable = true;

    environment.systemPackages = with pkgs; [
      # Lix Tooling
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
