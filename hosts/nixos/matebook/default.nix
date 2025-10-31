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
    ../../../modules/users/zeev
  ];

  # =================================================================
  # 2. System Configuration
  # =================================================================
  system.stateVersion = "25.05";

  sops.secrets.tailscale_auth_key = {
    sopsFile = ../../../secrets/tailscale-matebook.yaml;
    key = "tailscale_auth_key";
  };

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
  # 4. Environment
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
  # 5. Fonts
  # =================================================================
  fonts.fontconfig.useEmbeddedBitmaps = true;

  # =================================================================
  # 6. Home Manager
  # =================================================================
  home-manager.backupFileExtension = "backup";

  # =================================================================
  # 7. Networking
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
  # 8. Nix Configuration
  # =================================================================
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      cores = 8;
      max-jobs = 8;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      system-features = [
        "big-parallel"
        "gccarch-znver1"
        "kvm"
      ];
      substituters = [
        "https://4rmcyt-matebook.cachix.org"
      ];
      trusted-public-keys = [
        "4rmcyt-matebook.cachix.org-1:OG8MqlfrDlyperVhYk2+va8Cwo/vE6tG/VbTlvq4I0I="
      ];
      trusted-users = ["zeev"];
      warn-dirty = false;
    };
  };

  # =================================================================
  # 9. Programs
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
  # 10. Security
  # =================================================================
  security = {
    rtkit.enable = true;
    polkit.enable = true;
  };

  # =================================================================
  # 11. Services
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
    libinput.enable = true;
    libinput.touchpad = {
      tapping = true;
      naturalScrolling = true;
      scrollMethod = "twofinger";
    };
    displayManager.gdm.enable = true;

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

    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      authKeyFile = config.sops.secrets.tailscale_auth_key.path;
    };

    # Laptop-specific
    upower.enable = true;
    logind.settings.Login = {
      lidSwitch = "suspend";
      lidSwitchDocked = "ignore";
    };
  };

  # =================================================================
  # 12. Hardware-specific fixes
  # =================================================================
  # Enable brightness control
  programs.light.enable = true;

  # =================================================================
  # 13. Virtualization (optional)
  # =================================================================
  virtualisation.podman.enable = true;
}
