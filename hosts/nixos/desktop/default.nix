{
  pkgs,
  config,
  lib,
  ...
}: {
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
    ../../../modules/desktops/cosmic

    # Features and roles
    ../../../modules/gaming
    ../../../modules/networking/dnssec
    ../../../modules/kernel

    # User configuration
    ../../../modules/users/zeev

    # Disabled - uncomment when needed
    # ../../../modules/GUI/ollama
    # ../../../modules/GUI/OBS
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
      nix_access_token = {
        sopsFile = ../../../secrets/common.yaml;
        key = "nix_access_token";
      };
    };
    age.keyFile = "/root/.config/sops/age/keys.txt";
  };

  # =================================================================
  # 4. Boot Configuration
  # =================================================================
  boot = {
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
  # 6. Nix Configuration
  # =================================================================
  # Note: Base nix settings are in modules/base/nix-settings.nix
  # Only host-specific overrides are defined here
  nix = {
    channel.enable = true;
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      !include /run/secrets/nix_access_token
    '';
    settings = {
      cores = 0;

      experimental-features = [
        "flakes"
        "nix-command"
      ];

      auto-optimise-store = true;
      warn-dirty = false;
      max-jobs = "auto"; # Auto-detect job count
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
        "https://4rmcyt-desktop.cachix.org?priority=1"
        "https://cache.flox.dev?priority=2"
        "https://nixpkgs-unfree.cachix.org?priority=3"
        "https://nix-community.cachix.org?priority=4"
        "https://chaotic-nyx.cachix.org?priority=5"
        "https://cuda-maintainers.cachix.org?priority=6"
        "https://helix.cachix.org?priority=7"
        "https://yazi.cachix.org?priority=8"
        "https://devenv.cachix.org?priority=9"
        "https://nix-gaming.cachix.org?priority=10"
        "https://watersucks.cachix.org?priority=11"
      ];

      # Desktop-specific system features
      system-features = [
        "benchmark"
        "big-parallel"
        "gccarch-znver4"
        "kvm"
      ];

      # Additional trusted public keys for gaming and CUDA caches
      trusted-public-keys = [
        "4rmcyt-desktop.cachix.org-1:XqynXv73YM3p1hYM/LpGCRGNCcA8adK8WoSpXfOCZQs="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
        "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
        "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nqlt4="
        "watersucks.cachix.org-1:6gadPC5R8iLWQ3EUtfu3GFrVY7X6I4Fwz/ihW25Jbv8="
      ];

      trusted-users = [
        "root"
        "@wheel"
      ];
    };
  };

  # =================================================================
  # 7. Environment
  # =================================================================
  environment = {
    sessionVariables = lib.mkBefore {
      # GPG Agent for SSH (uses gpg-agent socket)
      SSH_AUTH_SOCK = "/run/user/$UID/gnupg/S.gpg-agent.ssh";

      # General nvidia settings
      GBM_BACKEND = "nvidia-drm";
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";
      XDG_CURRENT_DESKTOP = "sway";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      XDG_RUNTIME_DIR = "/run/user/$UID";

      # Wayland
      NIXOS_OZONE_WL = "1";
      XDG_SESSION_TYPE = "wayland";

      # Qt (allow Stylix to override QT_QPA_PLATFORMTHEME)
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_QPA_PLATFORMTHEME = lib.mkDefault "qt6ct";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_SCALE_FACTOR = "1";

      # GTK
      GDK_BACKEND = "wayland,x11";
      GDK_SCALE = "1";
      GTK_CSD = "1";
      GTK_DECORATION_LAYOUT = ":minimize,maximize,close";

      # Mozilla
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_WEBRENDER = "1";
      MOZ_ACCELERATED = "1";

      # XDG
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
    };

    shells = lib.mkBefore (with pkgs; [nushell]);

    systemPackages = lib.mkBefore (
      with pkgs; [
        # =============================================================
        # Audio & Multimedia
        # =============================================================
        helvum
        pavucontrol
        sof-firmware

        # =============================================================
        # Core System Utilities (desktop-specific)
        # =============================================================
        neofetch
        nodejs
        p7zip
        usbutils

        # =============================================================
        # Desktop Applications
        # =============================================================
        telegram-desktop
        # jellyfin-media-player

        # =============================================================
        # Development Tools (desktop-specific)
        # =============================================================
        direnv
        dockerfile-language-server
        gnumake
        just-lsp
        nh
        nix-fast-build
        nix-output-monitor
        nixfmt
        nixos-rebuild-ng

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
      allowedTCPPorts = [9100]; # Prometheus node exporter
      enable = true;
    };
    hostId = "e134040f";
    hostName = "desktop";
    networkmanager.enable = true;
    wireless.enable = false;
  };

  # =================================================================
  # 12. Programs
  # =================================================================
  programs = {
    corectrl.enable = true;

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
  # 13. Services
  # =================================================================
  services = {
    # =============================================================
    # Audio Services
    # =============================================================
    pipewire = {
      alsa = {
        enable = true;
        support32Bit = true;
      };
      audio.enable = true;
      enable = true;
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
      jack.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
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
      extraRemotes = ["lvfs-testing" "vendor"];
    };

    # Enable modprobed-db for automatic kernel module tracking
    # This will run hourly and store loaded modules to optimize future kernel builds
    modprobed-db = {
      enable = true;
      user = "root";
    };

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
      videoDrivers = ["nvidia"];
      xkb.layout = "us";
    };

    nixos-cli.enable = true;
  };
  # =================================================================
  # 14. Users & Groups
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
        shell = pkgs.nushell;
      };

      prometheus = {
        description = "Prometheus daemon user";
        group = "prometheus";
        isSystemUser = true;
      };

      zeev.shell = lib.mkForce pkgs.nushell;
    };
  };

  # =================================================================
  # 15. Virtualization
  # =================================================================
  virtualisation.podman.enable = true;

  # =================================================================
  # 16. Kernel Configuration
  # =================================================================
  # Optional: Enable to show kernel optimization instructions
  my.kernel.optimized.enable = true;

  # =================================================================
  # 17. Systemd Configuration
  # =================================================================
  systemd.tmpfiles.rules = [
    "d /data/zeev/Taildrive 770 davfs2 users -"
  ];

  # SSH config - written directly with correct permissions
  # (home-manager symlinks to nix store cause permission issues)
  system.activationScripts.sshConfig = ''
        mkdir -p /home/zeev/.ssh
        cat > /home/zeev/.ssh/config << 'EOF'
    Host *
      AddKeysToAgent yes
      ControlMaster auto
      ControlPersist 10m

    Host github.com
      IdentityFile ~/.ssh/zeev
      IdentitiesOnly yes
    EOF
        chown zeev:users /home/zeev/.ssh/config
        chmod 600 /home/zeev/.ssh/config
  '';
}
