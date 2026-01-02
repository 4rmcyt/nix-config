{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
{
  # =================================================================
  # 1. Imports
  # =================================================================
  imports = [
    # Hardware and system base
    ./hardware-configuration.nix
    ../../../modules/base
    ../../../modules/disko/desktop
    ../../../modules/options

    # Desktop environment
    ../../../modules/DE/kde

    # Features and roles
    ../../../modules/gaming
    ../../../modules/networking/dnssec
    ../../../modules/networking/ssh
    ../../../modules/networking/nut-client

    # User configuration
    ../../../modules/users/zeev
    # ../../../modules/GUI/ollama
    # ../../../modules/GUI/OBS

    ../../../modules/GUI/chromium
  ];

  # =================================================================
  # 2. System Configuration
  # =================================================================
  system.stateVersion = "25.05";

  # =================================================================
  # 3. Secrets Management
  # =================================================================
  sops = {
    secrets = {
      tailscale_auth_key = {
        sopsFile = ../../../secrets/tailscale-desktop.yaml;
        key = "tailscale_auth_key";
      };
      git_access_token = {
        sopsFile = ../../../secrets/common.yaml;
        key = "git_access_token";
      };
    };

    age.keyFile = "/root/.config/sops/age/keys.txt";
  };

  # =================================================================
  # 4. Boot Configuration
  # =================================================================
  boot = {
    kernelParams = [
      "usbcore.quirks=1462:7d75:k" # Disable autosuspend for MSI MYSTIC LIGHT
    ];

    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = false;
      limine = {
        enable = true;
        enableEditor = false;
        maxGenerations = 10;
        validateChecksums = true;
        panicOnChecksumMismatch = true;
        efiSupport = true;
        efiInstallAsRemovable = false;
        biosSupport = false;
      };
    };
  };

  # =================================================================
  # 5. Nixpkgs Configuration
  # =================================================================
  nixpkgs.config.cudaSupport = true;

  # =================================================================
  # 5.5. Security - PAM U2F for KWallet
  # =================================================================
  security.pam.services = {
    # Enable U2F authentication for login
    login.u2fAuth = true;

    # Enable U2F for KWallet unlock
    kwallet = {
      allowNullPassword = true;
      enableKwallet = true;
      u2fAuth = true;
    };

    # Enable U2F for sudo
    sudo.u2fAuth = true;
  };

  # PAM U2F configuration
  security.pam.u2f = {
    enable = true;
    control = "sufficient";
    settings = {
      cue = true;
    };
  };

  # =================================================================
  # 6. Nix Configuration
  # =================================================================
  nixpkgs.config.permittedInsecurePackages = [
    "ventoy-qt5-1.1.07"
  ];

  nix = {
    channel.enable = true;
    settings = {
      cores = 0;

      experimental-features = [
        "flakes"
        "nix-command"
        "flake-self-attrs"
        "lix-custom-sub-commands"
        "auto-allocate-uids"
      ];

      auto-optimise-store = true;

      warn-dirty = false;
      max-jobs = 8;
      keep-going = true; # Continue building other derivations on failure

      # Network optimization for faster downloads
      max-substitution-jobs = 4; # Parallel downloads
      http-connections = 25; # More HTTP connections
      connect-timeout = 5; # Faster timeout

      # Store optimization for better performance
      keep-outputs = true; # Keep build dependencies for faster rebuilds
      keep-derivations = true; # Keep derivations for faster evaluation

      # Disk space management
      min-free = 5368709120; # 5GB - trigger GC when less than 5GB free
      max-free = 10737418240; # 10GB - stop GC when 10GB free

      # Build performance improvements
      builders-use-substitutes = true; # Allow builders to use substitutes
      require-sigs = true; # Security: require signatures

      # Evaluation performance
      eval-cache = true; # Cache evaluation results

      substituters = [
        "https://cache.nixos.org"
        "https://4rmcyt-desktop.cachix.org?priority=1"
        "https://cache.lix.systems?priority=2"
        "https://cache.flox.dev?priority=3"
        "https://nix-community.cachix.org?priority=4"
        "https://chaotic-nyx.cachix.org?priority=5"
      ];

      # Desktop-specific system features
      extra-system-features = [
        "big-parallel"
        "kvm"
      ];

      # Additional trusted public keys for gaming and CUDA caches
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "4rmcyt-desktop.cachix.org-1:XqynXv73YM3p1hYM/LpGCRGNCcA8adK8WoSpXfOCZQs="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
        "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
        "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      ];

      trusted-users = [
        "root"
        "@wheel"
        "nix-builder"
      ];
    };
  };

  # =================================================================
  # 7. Environment
  # =================================================================
  environment = {
    sessionVariables = lib.mkBefore {
      # GPG Agent for SSH (uses gpg-agent socket)
      SSH_AUTH_SOCK = "/run/user/\${UID}/gnupg/S.gpg-agent.ssh";

      # General nvidia settings
      GBM_BACKEND = "nvidia-drm";
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";
      XDG_CURRENT_DESKTOP = "KDE";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";

      # Wayland
      NIXOS_OZONE_WL = "1";
      XDG_SESSION_TYPE = "wayland";

      # Qt Wayland - Disable client-side decorations to fix QWaylandGLContext errors
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

      # Additional Wayland optimizations for NVIDIA
      KWIN_DRM_USE_MODIFIERS = "1";
      WLR_NO_HARDWARE_CURSORS = "1";

      # Cursor theme
      XCURSOR_THEME = "breeze_cursors";
      XCURSOR_SIZE = "24";

      # XDG
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
    };

    shells = lib.mkBefore (
      with pkgs;
      [
        zsh
        nushell
      ]
    );

    systemPackages = lib.mkBefore (
      with pkgs;
      [
        # =============================================================
        # Audio & Multimedia
        # =============================================================
        helvum
        pavucontrol # PulseAudio Volume Control
        pamixer # Command-line mixer for PulseAudio
        bluez # Bluetooth support
        bluez-tools # Bluetooth tools
        sof-firmware
        inputs.nixos-jellyfin.packages.x86_64-linux.jellyfin-desktop

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
        atuin

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
        # ryzen-monitor-ng
        samba
        headset-charge-indicator
        yubikey-personalization
        limine-full
        # clan-cli

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
        yubioath-flutter

        # =============================================================
        # Secure Boot & EFI Tools
        # =============================================================
        efibootmgr
        ifrextractor-rs
        sbctl
        sbsigntool
        shim-unsigned
        optnix
        ventoy-full-qt
      ]
    );
  };

  # =================================================================
  # 8. Fonts
  # =================================================================
  fonts = {
    fontDir.enable = true;
    fontconfig.useEmbeddedBitmaps = true;
    packages = builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
  };

  # =================================================================
  # 9. Hardware
  # =================================================================
  hardware.amdgpu.overdrive.enable = true;

  # =================================================================
  # 10. Home Manager
  # =================================================================
  home-manager.backupFileExtension = "backup";

  # =================================================================
  # 11. Networking
  # =================================================================
  networking = {
    dnssec = {
      enable = true;
      profileId = "nextdns0";
    };
    enableIPv6 = false;
    firewall = {
      allowedTCPPorts = [ 9100 ]; # Prometheus node exporter
      enable = true;
    };
    hostId = "e134040f";
    hostName = "desktop";
    networkmanager.enable = true;
  };

  # =================================================================
  # 12. Programs
  # =================================================================
  programs = {
    corectrl.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-all;
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

    nix-ld.enable = true;

    noisetorch.enable = true;
    # vscode.enable = true;
  };

  # =================================================================
  # 13. Services
  # =================================================================
  services = {
    # =============================================================
    # Audio Services
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      wireplumber.enable = true;
      jack.enable = true;
      extraConfig.pipewire."92-low-latency" = {
        context.properties = {
          default.clock.max-quantum = 32;
          default.clock.min-quantum = 32;
          default.clock.quantum = 32;
          default.clock.rate = 48000;
        };
      };
      extraConfig.pipewire."93-screen-share" = {
        "stream.properties" = {
          "node.max-latency" = "1/60";
        };
        context.spa-libs = {
          "api.libcamera.*" = "libcamera/libspa-libcamera";
          "support.*" = "support/libspa-support";
        };
      };
      extraConfig.pipewire."99-usb-audio-fix" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 512;
          "default.clock.min-quantum" = 64;
          "default.clock.max-quantum" = 4096;
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

    fwupd = {
      enable = true;
      extraRemotes = [
        "lvfs-testing"
        "vendor"
      ];
    };

    openssh.enable = true;

    pcscd = {
      enable = true;
      plugins = [ pkgs.ccid ];
    };

    dbus.packages = [ pkgs.gcr ];

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
    # Networking Services
    # =============================================================
    tailscale = {
      authKeyFile = config.sops.secrets.tailscale_auth_key.path;
      enable = true;
      useRoutingFeatures = "both";
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

        # MSI MYSTIC LIGHT - Keep power management disabled (handled by kernel quirk)
        ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="1462", ATTRS{idProduct}=="7d75", TEST=="power/control", ATTR{power/control}="on"

        # Lock PC on yubikey removal
        ACTION=="remove",\
         ENV{ID_BUS}=="usb",\
         ENV{ID_MODEL_ID}=="0407",\
         ENV{ID_VENDOR_ID}=="1050",\
         ENV{ID_VENDOR}=="Yubico",\
         RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
      '';
      packages = with pkgs; [
        yubioath-flutter
        yubikey-manager
        yubikey-personalization
      ];
    };

    # =============================================================
    # X Server (for NVIDIA compatibility)
    # =============================================================
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      xkb.layout = "us";
    };
  };
  # =================================================================
  # 14. Users & Groups
  # =================================================================
  users = {
    groups = {
      git = { };
      plugdev = { };
      prometheus = { };
      nix-builder = { };
    };

    users = {
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

      # User for accepting remote nix builds
      nix-builder = {
        isSystemUser = true;
        group = "nix-builder";
        description = "Nix remote builder user";
        home = "/var/lib/nix-builder";
        createHome = true;
        shell = pkgs.bash;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ6N/kA0Cx1Swre7mQzWvqxL2o4TvD3l0hrAiNr0Qkcp nix-builder@homeserver"
        ];
      };

      zeev.shell = lib.mkForce pkgs.zsh;
    };
  };

  # =================================================================
  # 15. Virtualization
  # =================================================================
  virtualisation.podman.enable = true;
  systemd.tmpfiles.rules = [
    "d /data/zeev/Taildrive 770 davfs2 users -"
  ];
}
