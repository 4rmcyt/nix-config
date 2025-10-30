{pkgs, ...}: {
  # =================================================================
  # 1. Imports
  # =================================================================
  imports = [
    ./hardware-configuration.nix
    ../../../modules/base
    ../../../modules/users/zeev
  ];

  # =================================================================
  # 2. System Configuration
  # =================================================================
  system.stateVersion = "25.05";

  # =================================================================
  # 3. Boot Configuration
  # =================================================================
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };

  # =================================================================
  # 4. Internationalization & Time
  # =================================================================
  i18n.defaultLocale = "en_CA.UTF-8";
  time.timeZone = "America/Edmonton";

  # =================================================================
  # 5. Environment
  # =================================================================
  environment = {
    sessionVariables = {
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
      helix
      just
      nh
      nixfmt-rfc-style
      sops
      tmux
      zoxide

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

      # =============================================================
      # Desktop Applications
      # =============================================================
      # Add your preferred applications here

      # =============================================================
      # Fonts
      # =============================================================
      fira-code
      fira-mono
      meslo-lgs-nf
      nerd-fonts.droid-sans-mono
      nerd-fonts.fira-code
    ];
  };

  # =================================================================
  # 6. Fonts
  # =================================================================
  fonts.fontconfig.useEmbeddedBitmaps = true;

  # =================================================================
  # 7. Home Manager
  # =================================================================
  home-manager.backupFileExtension = "backup";

  # =================================================================
  # 8. Networking
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
    wireless.enable = false;
  };

  # =================================================================
  # 9. Nix Configuration
  # =================================================================
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      cores = 6;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      max-jobs = 6;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      trusted-users = ["zeev"];
      warn-dirty = false;
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
    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;

      # Configure keymap
      xkb = {
        layout = "us";
        variant = "";
      };

      # Touchpad support
      libinput = {
        enable = true;
        touchpad = {
          tapping = true;
          naturalScrolling = true;
          accelProfile = "adaptive";
        };
      };
    };

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

    thermald.enable = true;
    power-profiles-daemon.enable = false; # Conflicts with auto-cpufreq

    # =============================================================
    # Hardware Services
    # =============================================================
    fwupd.enable = true;

    # Printing support
    printing.enable = true;

    # Bluetooth
    blueman.enable = true;

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

    # Laptop-specific
    upower.enable = true;
    logind = {
      lidSwitch = "suspend";
      lidSwitchDocked = "ignore";
      extraConfig = ''
        HandlePowerKey=suspend
        IdleAction=suspend
        IdleActionSec=30min
      '';
    };
  };

  # =================================================================
  # 13. Hardware-specific fixes
  # =================================================================
  # Enable brightness control
  programs.light.enable = true;

  # =================================================================
  # 14. Virtualization (optional)
  # =================================================================
  virtualisation.podman.enable = true;
}
