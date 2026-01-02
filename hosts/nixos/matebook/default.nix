{
  pkgs,
  config,
  ...
}: {
  # =================================================================
  # 0. Nixpkgs Configuration
  # =================================================================
  nixpkgs.overlays = [
    # Disable ffado in pipewire to avoid nodejs ia32 cross-compilation issues
    # ffado is for FireWire audio devices which are rarely used
    (_final: prev: {
      pipewire = prev.pipewire.override {ffadoSupport = false;};
    })
  ];

  # =================================================================
  # 1. Imports
  # =================================================================
  imports = [
    # Hardware and system base
    ./hardware-configuration.nix
    ../../../modules/base
    ../../../modules/disko/matebook
    ../../../modules/options

    # Networking
    ../../../modules/networking/ssh

    # User configuration
    ../../../modules/users/zeev

    # GUI Applications
    ../../../modules/GUI/chromium
  ];

  # =================================================================
  # 2. System Configuration
  # =================================================================
  system.stateVersion = "25.05";

  # =================================================================
  # 3. Secrets Management
  # =================================================================
  sops.secrets = {
    tailscale_auth_key = {
      sopsFile = ../../../secrets/tailscale-matebook.yaml;
      key = "tailscale_auth_key";
    };
    git_access_token = {
      sopsFile = ../../../secrets/common.yaml;
      key = "git_access_token";
    };
  };

  # =================================================================
  # 4. Boot Configuration
  # =================================================================
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };

  # =================================================================
  # 5. Nix Configuration
  # =================================================================
  # nix.package is set by lix-module
  nix = {
    settings = {
      access-tokens = "github.com=REDACTED";
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

      # Substituters and trusted keys are centralized in flake.nix

      trusted-users = [
        "root"
        "@wheel"
      ];
    };
  };

  # =================================================================
  # 6. Environment
  # =================================================================
  environment = {
    sessionVariables = {
      # GPG Agent for SSH (uses gpg-agent socket)
      SSH_AUTH_SOCK = "/run/user/$UID/gnupg/S.gpg-agent.ssh";

      # AMD GPU variables
      LIBVA_DRIVER_NAME = "radeonsi";
      VDPAU_DRIVER = "radeonsi";

      # Wayland Support
      GDK_BACKEND = "wayland,x11";
      SDL_VIDEODRIVER = "wayland";
      CLUTTER_BACKEND = "wayland";
      MOZ_ENABLE_WAYLAND = "1";
    };

    systemPackages = with pkgs; [
      # =============================================================
      # Laptop-specific tools
      # =============================================================
      acpi
      brightnessctl
      powertop

      # =============================================================
      # Hardware Support & Monitoring
      # =============================================================
      fwupd

      fira-code
      fira-mono
      meslo-lgs-nf
      nerd-fonts.droid-sans-mono
      nerd-fonts.fira-code
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
    enableIPv6 = true;
    firewall = {
      enable = true;
    };
    hostName = "matebook";
    networkmanager = {
      enable = true;
      wifi.powersave = true;
    };
  };

  # =================================================================
  # 10. Programs
  # =================================================================
  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };

    light.enable = true;

    nh = {
      clean.enable = true;
      clean.extraArgs = "--keep-since 10d --keep 3";
      enable = true;
      flake = "/home/zeev/src/nix-config";
    };

    zsh.enable = true;
  };

  # =================================================================
  # 11. Security
  # =================================================================
  security = {
    rtkit.enable = true;
    polkit.enable = true;
  };

  # =================================================================
  # 12. Services
  # =================================================================
  services = {
    # =============================================================
    # Audio Services
    # =============================================================
    pipewire = {
      enable = true;
      audio.enable = true;
      pulse.enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      wireplumber.enable = true;
    };

    # =============================================================
    # Desktop Environment - GNOME
    # =============================================================
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;

    libinput.enable = true;
    libinput.touchpad = {
      tapping = true;
      naturalScrolling = true;
      scrollMethod = "twofinger";
    };

    # =============================================================
    # File Systems & Storage
    # =============================================================
    davfs2 = {
      enable = true;
      settings = {
        sections = {
          "/home/zeev/Taildrive" = {
            gui_optimize = true;
          };
        };
      };
    };

    # =============================================================
    # Hardware Services
    # =============================================================
    blueman.enable = true;

    pcscd = {
      enable = true;
      plugins = [pkgs.ccid];
    };

    thermald.enable = true;

    usbmuxd.enable = true;

    # =============================================================
    # Power Management
    # =============================================================
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          scaling_min_freq = 1400000;
          scaling_max_freq = 3500000;
          turbo = "never";
        };
        charger = {
          governor = "performance";
          scaling_min_freq = 1400000;
          scaling_max_freq = 4700000;
          turbo = "auto";
        };
      };
    };

    logind.settings.Login = {
      lidSwitch = "suspend";
      lidSwitchDocked = "ignore";
    };

    power-profiles-daemon.enable = false; # Conflicts with auto-cpufreq

    # =============================================================
    # System Services
    # =============================================================
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      authKeyFile = config.sops.secrets.tailscale_auth_key.path;
    };
  };

  # =================================================================
  # 13. Users & Groups
  # =================================================================
  users = {
    groups = {
      git = {};
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

      zeev.shell = pkgs.zsh;
    };
  };

  # =================================================================
  # 14. Virtualization
  # =================================================================
  virtualisation.podman.enable = true;
}
