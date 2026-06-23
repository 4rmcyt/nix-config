{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../modules/GUI/terminal
    ../../modules/GUI/IDE
    ../../modules/TUI/ai-tools
    ../../modules/TUI/ai-tools/llama-cpp

    ../../modules/GUI/chrome/home.nix
    ../../modules/GUI/chromium
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
    ../../modules/GUI/discord
    ../../modules/dev
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
      distrobox
      ffmpegthumbnailer
      foliate
      gst_all_1.gst-libav
      nvtopPackages.nvidia
      pcsc-tools
      pods
      popsicle
      signal-desktop
      slack
      vdpauinfo
      vulkan-tools
      ytmdesktop
      github-mcp-server
      terraform-mcp-server
      mcp-k8s-go
      mcp-grafana
      antigravity-fhs
      proton-pass
      proton-pass-cli
      seahorse
      (pkgs.texlive.combine {
        inherit
          (pkgs.texlive)
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
      mcat
      nmap
      arp-scan
      python313Packages.netifaces-plus
      tcpdump
      foot
      rt-tests
      claude-agent-acp
      opencode-desktop
      bettercap
      firefox
      libreoffice
      nixos-anywhere
      pmbootstrap
      fastboot
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

  # Break the cyclic ordering: set-SSH_AUTH_SOCK → Before=gpg-agent-ssh.socket
  # which is in sockets.target → basic.target → set-SSH_AUTH_SOCK (implicit After=basic.target).
  # Removing the socket-level Before/WantedBy; default.target is sufficient.
  systemd.user.services.set-SSH_AUTH_SOCK = {
    Unit.Before = lib.mkForce [];
    Install.WantedBy = lib.mkForce ["default.target"];
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };
}
