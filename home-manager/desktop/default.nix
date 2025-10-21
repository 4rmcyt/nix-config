{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../modules/GUI/firefox
    ../../modules/GUI/thunderbird
    ../shared/common.nix
    ../shared/zsh.nix
    ../shared/tmux.nix
  ];

  home = {
    username = "zeev";
    homeDirectory = "/home/zeev";
    stateVersion = "25.05";

    packages = with pkgs; [
      # Development tools
      bat
      busybox
      davfs2
      ffmpeg
      libva-utils
      pods
      pyenv
      python3
      vscode-fhs

      # Gaming
      steam
      vesktop

      # GUI applications
      ghostty
      jellyfin-media-player
      obsidian
      signal-desktop
      slack
      tail-tray
      tailscale
      ytmdesktop

      # KDE applications
      kdePackages.dolphin

      # Hardware monitoring
      nvtopPackages.nvidia

      # Security tools
      ccid
      pam_u2f
      pcsc-tools
      pinentry-qt

      # System information
      vdpauinfo
      vulkan-tools

      # Themes and icons
      gruvbox-dark-icons-gtk
      gruvbox-material-gtk-theme
      gruvbox-plus-icons
      kde-gruvbox

      # Browser with optimizations
      (chromium.override {
        enableWideVine = true;
        commandLineArgs = [
          "--enable-features=AcceleratedVideoEncoder,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE"
          "--enable-features=VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport"
          "--enable-features=UseMultiPlaneFormatForHardwareVideo"
          "--ignore-gpu-blocklist"
          "--enable-zero-copy"
        ];
      })
    ];

    sessionVariables = {
      # Graphics & Display
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";
      GDK_BACKEND = "wayland,x11";


      # Wayland Support
      NIXOS_OZONE_WL = "1";
      CLUTTER_BACKEND = "wayland";
      SDL_VIDEODRIVER = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";

      # Browser Optimization
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";
      MOZ_DISABLE_RDD_SANDBOX = "1";

      BROWSER = lib.mkForce "firefox";
    };
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = "Gruvbox-Dark";
      package = pkgs.gruvbox-dark-icons-gtk;
    };
    theme = {
      name = "breeze_transparent_dark";
      package = pkgs.kdePackages.breeze-gtk;
    };
  };

  programs = {
    browserpass.enable = true;

    ghostty = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        theme = "Dracula+";
        background-blur-radius = 40;
        background-opacity = 0.50;
        background-blur = true;
        minimum-contrast = 1.1;
        font-size = 14;
        font-family = "MesloLGS NF";
        window-theme = "system";
        window-show-tab-bar = "always";
        gtk-titlebar = true;
        shell-integration-features = "sudo";
      };
    };
  };

  programs.zsh.sessionVariables = lib.mkMerge [
    {
      EDITOR = "hx";
    }
  ];

  services.gpg-agent.enable = true;
}
