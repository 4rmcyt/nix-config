{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../modules/GUI/vscode
    ../../modules/GUI/ghostty
    ../../modules/GUI/wezterm
    ../../modules/GUI/mpv
    ../../modules/GUI/obsidian
    ../../modules/TUI/common
    ../../modules/TUI/zsh
    ../../modules/TUI/atuin
    ../../modules/TUI/zellij

    # Automatically imports the correct WM based on my.desktop.windowManager
    ../../modules/WM
  ];

  home = {
    homeDirectory = "/home/zeev";
    stateVersion = "24.11";
    username = "zeev";

    packages = with pkgs; [
      claude-code
      materialgram
      bat
      busybox
      devenv
      distrobox
      ffmpegthumbnailer
      foliate
      gst_all_1.gst-libav
      nvtopPackages.nvidia
      pcsc-tools
      pods
      popsicle
      pyenv
      signal-desktop
      slack
      tenv
      vdpauinfo
      vulkan-tools
      ytmdesktop
    ];

    sessionVariables = {
      BROWSER = lib.mkForce "chromium";
      EDITOR = lib.mkForce "hx";
      VISUAL = lib.mkForce "code";
    };
  };

  programs = {
    browserpass.enable = true;
    firefox.package = pkgs.firefox-nightly or pkgs.firefox;
    nushell.enable = true;
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };
}
