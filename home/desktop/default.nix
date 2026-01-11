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
    ../../modules/WM/niri
  ];

  home = {
    homeDirectory = "/home/zeev";
    stateVersion = "24.11";
    username = "zeev";

    packages = with pkgs; [
      azure-cli
      materialgram
      bat
      busybox
      devenv
      distrobox
      ffmpegthumbnailer
      foliate
      gst_all_1.gst-libav
      gvfs
      libva-utils
      nu_scripts
      nvtopPackages.nvidia
      pam_u2f
      pcsc-tools
      pods
      popsicle
      pyenv
      signal-desktop
      slack
      tailscale
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
