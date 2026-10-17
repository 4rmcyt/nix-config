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
      lixPackageSets.lix_2_96.nixpkgs-review
      lixPackageSets.lix_2_96.nix-eval-jobs
      lixPackageSets.lix_2_96.nix-fast-build
      lixPackageSets.lix_2_96.colmena
      lixPackageSets.lix_2_96.nix-direnv
      lixPackageSets.lix_2_96.boehmgc
      lixPackageSets.lix_2_96.nil
      lixPackageSets.lix_2_96.nurl
      lixPackageSets.lix_2_96.nix-init
      lixPackageSets.lix_2_96.nix-update
    ];
  };

  # nfs-client rides along here since only the GUI workstations mount homeserver's NFS shares.
  modules.nixos.workstationGui.imports = [
    ../modules/GUI/browsers/chrome
    ../modules/GUI/flatpak
    ../modules/GUI/kdeconnect
    ../modules/GUI/nemo
    ../modules/networking/nfs-client
  ];

  modules.homeManager.workstation = {
    imports = [
      ../modules/GUI/browsers/chrome/home.nix
      ../modules/GUI/browsers/firefox
      ../modules/GUI/browsers/zen
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

    # Not on homeserver: gpg-agent pinentry-tty ignores the plugin's ssh BatchMode and prompts on cd.
    programs.zsh.antidote.plugins = ["ohmyzsh/ohmyzsh path:plugins/git-auto-fetch"];
    programs.zsh.sessionVariables.GIT_AUTO_FETCH_INTERVAL = "300";
  };
}
