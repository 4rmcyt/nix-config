{
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ../../modules/TUI/ai-tools/llama-cpp/cpu.nix

    ../../modules/GUI/chrome/home.nix
    ../../modules/GUI/firefox
    inputs.private.homeManagerModules.thunderbird
    ../../modules/GUI/IDE/vscode
    ../../modules/GUI/terminal
    ../../modules/TUI/common
    ../../modules/TUI/helix
    ../../modules/TUI/neovim
    ../../modules/TUI/zsh
    ../../modules/TUI/tmux
    ../../modules/TUI/atuin
    ../../modules/GUI/mpv
    ../../modules/GUI/nemo/home.nix
    ../../modules/GUI/obsidian
    ../../modules/TUI/starship
    ../../modules/TUI/zellij
    ../../modules/WM/niri
    ../../modules/WM/niri/monitors/matebook.nix
    ../../modules/WM/niri/noctalia.nix
    ../../modules/WM/mime
    ../../modules/dev
    ../../modules/dev/git.nix
    ../../modules/security/gpg.nix
  ];
  home = {
    packages = with pkgs; [
      bat
      brightnessctl
      davfs2
      materialgram
      pam_u2f
      pcsc-tools
      pinentry-qt
      ryzen-monitor-ng
      signal-desktop
      slack
      yubioath-flutter
    ];

    sessionVariables = {
      # Graphics & Display (AMD) — Wayland vars provided by modules/WM/niri
      LIBVA_DRIVER_NAME = "radeonsi";
      VDPAU_DRIVER = "radeonsi";

      BROWSER = lib.mkForce "firefox";
      PYENV_ROOT = "$HOME/.pyenv";
    };
  };

  services.gpg-agent.enable = true;
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
  };
}
