{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../modules/GUI/chrome/home.nix
    ../../modules/GUI/firefox
    ../../modules/GUI/thunderbird
    ../../modules/GUI/IDE/vscode
    ../../modules/GUI/terminal/ghostty
    ../../modules/GUI/terminal/kitty
    ../../modules/TUI/common
    ../../modules/TUI/zsh
    ../../modules/TUI/tmux
    ../../modules/TUI/atuin
    ../../modules/GUI/mpv
    ../../modules/GUI/obsidian
    ../../modules/TUI/starship
    ../../modules/TUI/zellij
    ../../modules/WM/niri
    ../../modules/WM/niri/monitors/matebook.nix
    ../../modules/WM/niri/noctalia.nix
    ../../modules/GUI/mime
  ];
  home = {
    username = "zeev";
    homeDirectory = "/home/zeev";

    packages = with pkgs; [
      bat
      brightnessctl
      davfs2
      materialgram
      nautilus
      pam_u2f
      pcsc-tools
      pinentry-qt
      ryzen-monitor-ng
      signal-desktop
      slack
      ytmdesktop
      yubioath-flutter
    ];

    sessionVariables = {
      # Graphics & Display (AMD) — Wayland vars provided by modules/WM/niri
      LIBVA_DRIVER_NAME = "radeonsi";
      VDPAU_DRIVER = "radeonsi";

      EDITOR = lib.mkForce "hx";
      BROWSER = lib.mkForce "google-chrome-stable";
    };
  };

  programs = {
    browserpass.enable = true;
  };

  services.gpg-agent.enable = true;
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
  };
}
