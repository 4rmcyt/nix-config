{
  pkgs,
  config,
  ...
}: {
  # =================================================================
  # 1. Imports
  # =================================================================
  imports = [
    ./hardware-configuration.nix
    ../../../modules/base
    ../../../modules/disko/desktop
    ../../../modules/gaming
    ../../../modules/networking/dnssec
    ../../../modules/users/zeev
    # ../../../modules/GUI/ollama
    ../../../modules/GUI/OBS
    ../../../modules/GUI/flatpak
  ];

  # =================================================================
  # 2. System Configuration
  # =================================================================
  system.stateVersion = "25.05";

  users.users.tailscale = {
    isSystemUser = true;
    group = "tailscale";
  };
  users.groups.tailscale = {};

  sops.secrets.tailscale_auth_key = {
    sopsFile = ../../../secrets/tailscale-desktop.yaml;
    key = "tailscale_auth_key";
    owner = config.users.users.tailscale.name;
  };

  # =================================================================
  # 3. Boot Configuration
  # =================================================================
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = false;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };

  # =================================================================
  # 5. Internationalization & Time
  # =================================================================
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Edmonton";

  # =================================================================
  # 6. Environment
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

    systemPackages = with pkgs; [
      # =============================================================
      # Core System Utilities
      # =============================================================
      btop
      curl
      git
      htop
      mc
      neofetch
      openssl
      p7zip
      pciutils
      unzip
      usbutils
      vim
      wget

      # =============================================================
      # Development Tools
      # =============================================================
      age
      alejandra
      cachix
      cmake-format
      deadnix
      direnv
      dockfmt
      dockerfile-language-server
      gnumake
      helix
      just
      just-lsp
      nh
      nix-diff
      nix-fast-build
      nix-output-monitor
      nixfmt
      nixfmt-rfc-style
      nixos-rebuild-ng
      nodePackages.prettier
      rustfmt
      shfmt
      sops
      statix
      toml-sort
      treefmt
      yamlfmt
      zoxide
      tmux

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
      nvtopPackages.nvidia
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
    ];
  };

  # =================================================================
  # 7. Fonts
  # =================================================================
  fonts.fontconfig.useEmbeddedBitmaps = true;

  # =================================================================
  # 8. Home Manager
  # =================================================================
  home-manager.backupFileExtension = "backup";

  # =================================================================
  # 9. Networking
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
  # 10. Nix Configuration
  # =================================================================
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      cores = 12;
      download-buffer-size = 1073741824;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      fallback = true;
      max-jobs = 12;
      show-trace = true;
      substituters = [
        "https://cache.nixos.org"
        "https://4rmcyt.cachix.org"
        "https://cuda-maintainers.cachix.org"
        "https://nix-community.cachix.org"
        "https://nix-gaming.cachix.org"
      ];
      system-features = [
        "benchmark"
        "big-parallel"
        "gccarch-znver4"
        "kvm"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "4rmcyt.cachix.org-1:IzZEPOd8aKavFKw3BuUBAI/T93XUUWoS/n2M+LG65/0="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      ];
      trusted-users = ["zeev"];
      warn-dirty = false;
    };
  };

  # =================================================================
  # 11. Programs
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
    zsh.enable = true;
    # vscode.enable = true;
  };

  # =================================================================
  # 12. Security
  # =================================================================
  security = {
    rtkit.enable = true;
    polkit.enable = true;
  };

  # =================================================================
  # 13. Secrets Management
  # =================================================================
  sops.age.keyFile = "/root/.config/sops/age/keys.txt";

  # =================================================================
  # 14. Services
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
  # 15. Users & Groups
  # =================================================================
  users = {
    groups = {
      git = {};
      plugdev = {};
      prometheus = {};
    };
    users = {
      git = {
        createHome = true;
        description = "Git user";
        group = "git";
        home = "/var/lib/git";
        isSystemUser = true;
        shell = pkgs.zsh;
      };
      prometheus = {
        description = "Prometheus daemon user";
        group = "prometheus";
        isSystemUser = true;
      };
    };
  };

  # =================================================================
  # 16. Virtualization
  # =================================================================
  virtualisation.podman.enable = true;

  # =================================================================
  # 17. XDG Portal
  # =================================================================
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
    ];
  };

  # =================================================================
  # 18. Systemd Configuration
  # =================================================================
  systemd.tmpfiles.rules = [
    "d /data/zeev/Taildrive 770 davfs2 users -"
  ];
}
