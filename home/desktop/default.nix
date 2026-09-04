{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../modules/GUI/IDE
    ../../modules/TUI/ai-tools
    ../../modules/TUI/ai-tools/llama-cpp
    ../../modules/TUI/ai-tools/llama-cpp/qwen32b-cpu.nix

    ../../modules/GUI/bb-launcher
    ../../modules/GUI/chromium
    ../../modules/GUI/jellyfin-mpv-shim

    ../../modules/WM
    ../../modules/WM/mango
    ../../modules/WM/mango/nvidia.nix
    ../../modules/WM/mango/monitors/desktop.nix
    ../../modules/GUI/discord
    ../../modules/GUI/easyeffects
    ../../modules/dev/android.nix
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
    packages = with pkgs; [
      android-tools
      arp-scan
      bat
      bettercap
      claude-agent-acp
      distrobox
      ffmpegthumbnailer
      foliate
      foot
      github-mcp-server
      gst_all_1.gst-libav
      ifrextractor-rs
      jellycli
      jujutsu
      libreoffice
      materialgram
      mcat
      mcp-grafana
      mcp-k8s-go
      nixos-anywhere
      nmap
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
      supersonic
      tcpdump
      terraform-mcp-server
      uefitool
      uefitoolPackages.old-engine
      vdpauinfo
      vulkan-tools
      waydroid-helper
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
