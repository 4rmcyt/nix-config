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
    ../../modules/GUI/firefox
    ../../modules/GUI/mpv
    ../../modules/GUI/obsidian
    ../../modules/TUI/common
    ../../modules/TUI/helix
    ../../modules/TUI/neovim
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
    ../../modules/dev/git.nix
    ../../modules/security/gpg.nix
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
      jujutsu
      (pkgs.texliveSmall.withPackages (ps:
        with ps; [
          scheme-medium
          moderncv
          lastpage
          enumitem
          fontawesome
          pgf
          mhchem
          xcolor
        ]))
      pkgs.nur.repos.codgician.samsung-dc-toolkit-3
      pkgs.nur.repos.codgician.waydroid-script
    ];

    sessionVariables = {
      BROWSER = lib.mkForce "google-chrome-stable";
      VISUAL = lib.mkForce "code";
      PYENV_ROOT = "$HOME/.pyenv";
    };
  };

  programs = {
    claude-code.enable = true;
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
