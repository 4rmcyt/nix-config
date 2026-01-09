{
  pkgs,
  lib,
  ...
}: {
  imports = [
    # ../../modules/DE/kde/plasma-manager.nix
    # ../../modules/GUI/firefox
    # ../../modules/GUI/thunderbird
    ../../modules/GUI/vscode
    ../../modules/GUI/ghostty
    ../../modules/GUI/wezterm
    # ../../modules/GUI/zed
    ../../modules/GUI/mpv
    ../../modules/GUI/obsidian
    # ../../modules/GUI/noctalia
    # ../../modules/GUI/konsole
    ../../modules/TUI/common
    ../../modules/TUI/zsh
    # ../../modules/TUI/tmux
    # ../../modules/TUI/nushell
    # ../../modules/TUI/starship
    ../../modules/TUI/atuin
    ../../modules/TUI/zellij
    ../../modules/WM/niri
  ];

  home = {
    homeDirectory = "/home/zeev";
    stateVersion = "24.11";
    username = "zeev";

    packages = with pkgs; [
      # Development tools
      azure-cli
      bat
      busybox
      libva-utils
      pods
      pyenv
      tenv
      nu_scripts
      devenv

      # Containerization
      distrobox

      # GUI applications
      signal-desktop
      slack
      tailscale
      ytmdesktop
      popsicle
      ayugram-desktop

      foliate
      gvfs
      ffmpegthumbnailer
      gst_all_1.gst-libav

      # Hardware monitoring
      nvtopPackages.nvidia

      # Security tools
      pam_u2f
      pcsc-tools

      # System information
      vdpauinfo
      vulkan-tools
    ];

    sessionVariables = {
      BROWSER = lib.mkForce "chromium";
      EDITOR = lib.mkForce "hx";
      VISUAL = lib.mkForce "code";
    };
  };

  programs = {
    browserpass.enable = true;
    nushell.enable = true;

    # Firefox with nightly package
    firefox.package = pkgs.firefox-nightly or pkgs.firefox;
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  # systemd.user.services.niri-flake-polkit.enable = false;
}
