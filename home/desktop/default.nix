{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../modules/GUI/vscode
    ../../modules/GUI/pycharm
    ../../modules/GUI/ghostty
    ../../modules/GUI/wezterm
    ../../modules/GUI/mpv
    ../../modules/GUI/obsidian
    ../../modules/TUI/common
    ../../modules/TUI/zsh
    ../../modules/TUI/atuin
    ../../modules/TUI/zellij
    ../../modules/TUI/calendar
    ../../modules/TUI/gemini-cli

    # WM base config (XDG, zed, etc.)
    ../../modules/WM
    # Hyprland window manager config
    ../../modules/WM/hyprland
  ];

  home = {
    homeDirectory = "/home/zeev";
    stateVersion = "24.11";
    username = "zeev";

    packages = with pkgs; [
      nautilus
      mcp-nixos
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
      mise
      ytmdesktop
      playwright
      python313Packages.playwright
      python313Packages.pytest-playwright
      playwright-mcp

      # Python with common packages
      (python3.withPackages (
        ps:
          with ps; [
            pip
            pydantic
            requests
            black
            pylint
            python-lsp-server
          ]
      ))
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
