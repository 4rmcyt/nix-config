{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../modules/GUI/terminal
    ../../modules/GUI/IDE
    ../../modules/TUI/ai-tools

    ../../modules/GUI/mpv
    ../../modules/GUI/obsidian
    ../../modules/TUI/common
    ../../modules/TUI/zsh
    ../../modules/TUI/atuin
    ../../modules/TUI/zellij
    # ../../modules/TUI/calendar  # khal broken in nixpkgs (sphinx-feed)

    ../../modules/WM
    ../../modules/WM/niri
    ../../modules/WM/niri/nvidia.nix
    ../../modules/WM/niri/monitors.nix
  ];

  # WirePlumber: always use SBC-XQ for OpenRun Pro 2 (best codec it supports)
  xdg.configFile."wireplumber/wireplumber.conf.d/51-shokz-openrun.conf".text = ''
    monitor.bluez.rules = [
      {
        matches = [
          { device.name = "bluez_card.A0_0C_E2_7B_7F_4A" }
        ]
        actions = {
          update-props = {
            bluez5.auto-connect = [ "a2dp_sink" ]
            bluez5.profile = "a2dp-sink-sbc_xq"
          }
        }
      }
    ]
  '';

  home = {
    homeDirectory = "/home/zeev";

    username = "zeev";

    packages = with pkgs; [
      easyeffects
      jellycli
      supersonic-wayland
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
      (pkgs.texlive.combine {
        inherit
          (pkgs.texlive)
          scheme-medium
          lastpage
          enumitem
          fontawesome
          pgf
          mhchem
          xcolor
          ;
      })
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

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-gnome3;
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };
}
