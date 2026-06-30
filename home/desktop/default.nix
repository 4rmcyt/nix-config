{
  pkgs,
  lib,
  ...
}: {
  nixpkgs.config.permittedInsecurePackages = ["pnpm-10.29.2"];
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

    ../../modules/WM
    ../../modules/WM/niri
    ../../modules/WM/niri/noctalia.nix
    ../../modules/WM/niri/nvidia.nix
    ../../modules/WM/niri/monitors/desktop.nix
    ../../modules/WM/mime
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
      android-tools
      antigravity-fhs
      arp-scan
      bat
      bettercap
      claude-agent-acp
      distrobox
      easyeffects
      ffmpegthumbnailer
      firefox
      foliate
      foot
      github-mcp-server
      gst_all_1.gst-libav
      ifrextractor-rs
      jellycli
      libreoffice
      materialgram
      mcat
      mcp-grafana
      mcp-k8s-go
      nmap
      nixos-anywhere
      nvtopPackages.nvidia
      opencode-desktop
      pcsc-tools
      pmbootstrap
      pods
      popsicle
      proton-pass
      proton-pass-cli
      python313Packages.netifaces-plus
      rt-tests
      seahorse
      signal-desktop
      slack
      supersonic-wayland
      tcpdump
      terraform-mcp-server
      uefitool
      uefitoolPackages.old-engine
      vdpauinfo
      vulkan-tools
      waydroid-helper
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
      pkgs.nur.repos.codgician.samsung-dc-toolkit-3
      pkgs.nur.repos.codgician.waydroid-script
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
