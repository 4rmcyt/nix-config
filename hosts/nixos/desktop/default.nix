{
  pkgs,
  config,
  lib,
  ...
}: {
  # =================================================================
  # Imports
  # =================================================================
  imports = [
    # Hardware and system base
    ./hardware-configuration.nix
    ../../../modules/base
    ../../../modules/disko/desktop
    ../../../modules/options

    # Features and roles
    ../../../modules/gaming
    ../../../modules/GUI/flatpak
    ../../../modules/networking/dnssec

    # User configuration
    ../../../modules/users/zeev

    # Disabled - uncomment when needed
    # ../../../modules/GUI/ollama
    # ../../../modules/GUI/OBS
  ];

  # =================================================================
  # System Configuration
  # =================================================================
  system.stateVersion = "25.05";

  sops.secrets.tailscale_auth_key = {
    sopsFile = ../../../secrets/tailscale-desktop.yaml;
    key = "tailscale_auth_key";
  };

  # =================================================================
  # Boot Configuration
  # =================================================================
  boot = {
    loader = {
      efi.canTouchEfiVariables = false;
      systemd-boot.enable = true;
    };
    lanzaboote = {
      enable = false;
      pkiBundle = "/var/lib/sbctl";
    };
  };

  # =================================================================
  # Environment
  # =================================================================
  environment = {
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
    };

    systemPackages = lib.mkBefore (with pkgs; [
      # =============================================================
      # Core System Utilities (desktop-specific)
      # =============================================================
      # Common packages now provided by modules/base/common-packages.nix
      neofetch
      p7zip
      usbutils
      nodejs

      # =============================================================
      # Development Tools (desktop-specific)
      # =============================================================
      # Common dev tools now provided by modules/base/common-packages.nix
      direnv
      dockerfile-language-server
      gnumake
      just-lsp
      nh
      nix-fast-build
      nix-output-monitor
      nixfmt
      nixos-rebuild-ng
      treefmt

      # =============================================================
      # Audio & Multimedia
      # =============================================================
      helvum
      pavucontrol
      sof-firmware

      # =============================================================
      # Desktop Applications
      # =============================================================
      telegram-desktop
      # jellyfin-media-player

      # =============================================================
      # Fonts & Themes
      # =============================================================
      fira-code
      fira-mono
      meslo-lgs-nf
      nerd-fonts.droid-sans-mono
      nerd-fonts.fira-code
      sddm-astronaut
      sddm-sugar-dark

      # =============================================================
      # Graphics & GPU
      # =============================================================
      libdbusmenu
      libva-utils
      nvidia-vaapi-driver

      # =============================================================
      # Hardware Support & Monitoring
      # =============================================================
      apcupsd
      cifs-utils
      fwupd
      microcode-amd
      # nvtopPackages.nvidia
      openrgb-with-all-plugins
      powertop
      ryzen-monitor-ng
      samba

      # =============================================================
      # KDE Applications
      # =============================================================
      kdePackages.ark
      kdePackages.discover
      kdePackages.filelight
      kdePackages.gwenview
      kdePackages.kcalc
      kdePackages.kcharselect
      kdePackages.kclock
      kdePackages.kfind
      kdePackages.kgpg
      kdePackages.kio-extras
      kdePackages.konsole
      kdePackages.ksystemlog
      kdePackages.kate
      kdePackages.okular
      kdePackages.partitionmanager
      kdePackages.plasma-browser-integration
      kdePackages.qtmultimedia
      kdePackages.qtsvg
      kdePackages.sddm-kcm
      kdePackages.signon-kwallet-extension
      kdePackages.spectacle
      kdePackages.systemsettings
      kwalletcli
      kdePackages.qtwayland
      libsForQt5.qt5.qtwayland

      # =============================================================
      # Security & Encryption
      # =============================================================
      ccid
      libfido2
      (pass.withExtensions (exts: [
        exts.pass-checkup
        exts.pass-file
        exts.pass-genphrase
        exts.pass-import
        exts.pass-otp
        exts.pass-update
      ]))
      pass-wayland
      pinentry-curses
      yubico-pam
      yubico-piv-tool
      yubikey-manager
      yubioath-flutter

      # =============================================================
      # Secure Boot & EFI Tools
      # =============================================================
      efibootmgr
      efitools
      ifrextractor-rs
      sbctl
      sbsigntool
      shim-unsigned
      uefitool

      # =============================================================
      # Disabled due to CMake compatibility issues
      # =============================================================
      # dfu-util
      # qmk
      # qmk-udev-rules
      # via
    ]);
  };

  # =================================================================
  # Fonts
  # =================================================================
  fonts.fontconfig.useEmbeddedBitmaps = true;

  # =================================================================
  # Home Manager
  # =================================================================
  home-manager.backupFileExtension = "backup";

  # =================================================================
  # Networking
  # =================================================================
  networking = {
    dnssec = {
      enable = true;
      profileId = "nextdns0";
    };
    enableIPv6 = false;
    firewall = {
      allowedTCPPorts = [9100]; # Prometheus node exporter
      enable = true;
    };
    hostId = "e134040f";
    hostName = "desktop";
    networkmanager.enable = true;

    wireless.enable = false;
  };

  # =================================================================
  # Nix Configuration
  # =================================================================
  # Note: Base nix settings are in modules/base/nix-settings.nix
  # Only host-specific overrides are defined here
  nix.settings = {
    cores = 12;
    max-jobs = 12;

    # Additional gaming and CUDA caches
    substituters = [
      "https://4rmcyt-desktop.cachix.org"
      "https://cuda-maintainers.cachix.org"
      "https://nix-community.cachix.org"
      "https://nix-gaming.cachix.org"
    ];

    # Desktop-specific system features
    system-features = [
      "benchmark"
      "big-parallel"
      "gccarch-znver4"
      "kvm"
    ];

    experimental-features = [
      "flakes"
      "nix-command"
    ];

    # Additional trusted public keys for gaming and CUDA caches
    trusted-public-keys = [
      "4rmcyt-desktop.cachix.org-1:XqynXv73YM3p1hYM/LpGCRGNCcA8adK8WoSpXfOCZQs="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    ];

    # Allow zeev to use nix commands without sudo
    trusted-users = ["zeev"];

    # Disable dirty warnings for desktop
    warn-dirty = false;
  };

  # =================================================================
  # Programs
  # =================================================================
  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-qt;
    };
    nh = {
      clean.enable = true;
      clean.extraArgs = "--keep-since 10d --keep 3";
      enable = true;
      flake = "/home/zeev/src/nix-config";
    };
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };
    # vscode.enable = true;
  };

  # =================================================================
  # Security
  # =================================================================
  security = {
    rtkit.enable = true;
    polkit.enable = true;
  };

  # =================================================================
  # Secrets Management
  # =================================================================
  sops.age.keyFile = "/root/.config/sops/age/keys.txt";

  # =================================================================
  # Services
  # =================================================================
  services = {
    # =============================================================
    # Audio Services
    # =============================================================
    pipewire = {
      enable = true;
      audio.enable = true;
      pulse.enable = true;
      jack.enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      wireplumber.enable = true;
      extraConfig.pipewire."92-low-latency" = {
        context.properties = {
          default.clock.rate = 48000;
          default.clock.quantum = 32;
          default.clock.min-quantum = 32;
          default.clock.max-quantum = 32;
        };
      };
      extraConfig.pipewire."93-screen-share" = {
        "stream.properties" = {
          "node.max-latency" = "1/60";
        };
        context.spa-libs = {
          "support.*" = "support/libspa-support";
          "api.libcamera.*" = "libcamera/libspa-libcamera";
        };
      };
    };
    pulseaudio.enable = false;

    # =============================================================
    # Desktop Environment
    # =============================================================
    desktopManager.plasma6.enable = true;
    displayManager = {
      autoLogin = {
        enable = true;
        user = "zeev";
      };
      sddm = {
        autoNumlock = true;
        enable = true;
        enableHidpi = true;
        theme = "breeze";
        wayland.compositor = "kwin";
        wayland.enable = true;
      };
    };

    # =============================================================
    # File Systems & Storage
    # =============================================================
    davfs2 = {
      enable = true;
      settings = {
        sections = {
          "/data/zeev/Taildrive" = {
            gui_optimize = true;
          };
        };
      };
    };

    # =============================================================
    # Hardware Services
    # =============================================================
    auto-cpufreq = {
      enable = true;
      settings.charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
    fwupd.enable = true;
    openssh.enable = true;
    pcscd = {
      enable = true;
      plugins = [pkgs.ccid];
    };
    power-profiles-daemon.enable = false;
    usbmuxd.enable = true;

    # =============================================================
    # Monitoring Services
    # =============================================================
    prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [
        "cpu"
        "diskstats"
        "filesystem"
        "netdev"
        "stat"
        "textfile"
        "time"
        "zfs"
      ];
      listenAddress = "0.0.0.0";
      port = 9100;
    };

    # =============================================================
    # Hardware Peripherals
    # =============================================================
    udev = {
      extraRules = ''
        # QMK keyboard rules
        SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ff4", MODE="0666", GROUP="plugdev"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ffb", MODE="0666", GROUP="plugdev"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="174c", ATTRS{idProduct}=="2074", MODE="0666", GROUP="plugdev"

        # Gaming device rules
        SUBSYSTEM=="input", ATTRS{name}=="Rapoo Rapoo Gaming Device", TAG+="uaccess"
      '';
      packages = with pkgs; [
        yubioath-flutter
        yubikey-manager
        yubikey-personalization
      ];
    };

    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      authKeyFile = config.sops.secrets.tailscale_auth_key.path;
    };

    # =============================================================
    # X Server (for NVIDIA compatibility)
    # =============================================================
    xserver = {
      enable = true;
      videoDrivers = ["nvidia"];
      xkb.layout = "us";
    };
  };

  # =================================================================
  # Users & Groups
  # =================================================================
  users = {
    groups = {
      git = {};
      plugdev = {};
      prometheus = {};
    };
    users = {
      zeev.shell = lib.mkForce pkgs.nushell;
      git = {
        createHome = true;
        description = "Git user";
        group = "git";
        home = "/var/lib/git";
        isSystemUser = true;
        shell = pkgs.nushell;
      };
      prometheus = {
        description = "Prometheus daemon user";
        group = "prometheus";
        isSystemUser = true;
      };
    };
  };

  # =================================================================
  # Virtualization
  # =================================================================
  virtualisation.podman.enable = true;

  # =================================================================
  # XDG Portal
  # =================================================================
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
    ];
  };

  # =================================================================
  # Systemd Configuration
  # =================================================================
  systemd.tmpfiles.rules = [
    "d /data/zeev/Taildrive 770 davfs2 users -"
  ];
}
