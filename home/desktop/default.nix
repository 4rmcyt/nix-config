{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../../modules/GUI/terminal
    ../../modules/GUI/IDE
    ../../modules/TUI/ai-tools

    ../../modules/GUI/chrome/home.nix
    ../../modules/GUI/mpv
    ../../modules/GUI/obsidian
    ../../modules/TUI/common
    ../../modules/TUI/zsh
    ../../modules/TUI/atuin
    ../../modules/TUI/zellij
    # ../../modules/TUI/calendar  # khal broken in nixpkgs (sphinx-feed)

    ../../modules/WM
    ../../modules/WM/niri
    ../../modules/WM/niri/noctalia.nix
    ../../modules/WM/niri/nvidia.nix
    ../../modules/WM/niri/monitors/desktop.nix
    ../../modules/GUI/mime
  ];

  # WirePlumber: upower is disabled on desktop (no battery) — silence the D-Bus NameHasNoOwner errors
  xdg.configFile."wireplumber/wireplumber.conf.d/50-no-upower.conf".text = ''
    wireplumber.components.rules = [
      {
        matches = [ { name = "upower_monitor" } ]
        actions = { override = { type = "disabled" } }
      }
    ]
  '';

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
      github-mcp-server
      terraform-mcp-server
      mcp-k8s-go
      mcp-grafana
      nodejs
      uv
      antigravity-fhs
      proton-pass
      proton-pass-cli
      seahorse
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
      (pkgs.texlive.combine {
        inherit (pkgs.texlive)
          scheme-medium
          moderncv
          lastpage
          enumitem
          fontawesome
          pgf
          mhchem
          xcolor
          ;
      })
      uefitool
      uefitoolPackages.old-engine
      ifrextractor-rs
      waydroid-helper
      pkgs.nur.repos.codgician.samsung-dc-toolkit-3
      pkgs.nur.repos.codgician.waydroid-script
      calibre-no-speech
      mcat
      nmap
      arp-scan
      python313Packages.netifaces-plus
      gcc
      tcpdump
      foot
      rt-tests
      claude-agent-acp
      opencode-desktop
      bettercap
      pnpm
      supabase-cli
      wrangler
      chromium
    ];

    sessionVariables = {
      BROWSER = lib.mkForce "google-chrome-stable";
      EDITOR = lib.mkForce "hx";
      VISUAL = lib.mkForce "code";
    };
  };

  programs = {
    claude-code.enable = true;
    firefox.package = pkgs.firefox;
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-gnome3;
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
