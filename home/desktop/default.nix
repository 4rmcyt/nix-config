{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../../modules/GUI/vscode
    # ../../modules/GUI/pycharm
    ../../modules/GUI/terminal
    ../../modules/GUI/mpv
    ../../modules/GUI/obsidian
    ../../modules/TUI/common
    ../../modules/TUI/zsh
    ../../modules/TUI/atuin
    ../../modules/TUI/zellij
    ../../modules/TUI/calendar
    ../../modules/TUI/gemini-cli
    ../../modules/TUI/mcp
    ../../modules/TUI/claude-code
    ../../modules/WM
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
      github-mcp-server
      terraform-mcp-server
      mcp-k8s-go
      mcp-grafana
      nodejs
      uv
      antigravity-fhs
      proton-pass
      proton-pass-cli
      (python3.withPackages (
        ps: with ps; [
          pip
          pydantic
          requests
          black
          pylint
          python-lsp-server
        ]
      ))

      opencode
      opencode-desktop
    ];

    sessionVariables = {
      BROWSER = lib.mkForce "chromium";
      EDITOR = lib.mkForce "hx";
      VISUAL = lib.mkForce "code";
    };
  };

  programs = {
    browserpass.enable = true;
    claude-code.enable = true;
    firefox.package = pkgs.firefox-nightly or pkgs.firefox;
    nushell.enable = true;
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
