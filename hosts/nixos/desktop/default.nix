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

    # Desktop environment
    ../../../modules/desktops/cosmic

    # Features and roles
    ../../../modules/gaming
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

  sops.secrets.git_access_token = {
    sopsFile = ../../../secrets/common.yaml;
    key = "git_access_token";
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
    shells = with pkgs; [nushell];

    sessionVariables = {
      # NVIDIA-specific settings
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";
    };

    systemPackages = lib.mkBefore (
      with pkgs; [
        # Core System Utilities (desktop-specific)
        neofetch
        p7zip
        usbutils
        nodejs

        # Development Tools (desktop-specific)
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

        # =============================================================
        # Graphics & GPU
        # =============================================================
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
        pinentry-all
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
      ]
    );
  };

  # =================================================================
  # Fonts
  # =================================================================

  fonts = {
    fontconfig.useEmbeddedBitmaps = true;
    fontDir.enable = true;
    packages = builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
  };

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
  # Systemd Configuration
  # =================================================================
  systemd.tmpfiles.rules = [
    "d /data/zeev/Taildrive 770 davfs2 users -"
  ];
}
