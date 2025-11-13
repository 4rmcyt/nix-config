{
  pkgs,
  config,
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
    ../../../modules/disko/matebook
    ../../../modules/options

    # User configuration
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
      git-crypt
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
      nodejs
      cachix

      # =============================================================
      # Development Tools
      # =============================================================
      age
      alejandra
      deadnix
      direnv
      helix
      just
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
      system-features = [
        "big-parallel"
        "gccarch-znver1"
        "kvm"
      ];
      substituters = [
        "https://4rmcyt-matebook.cachix.org?priority=1"
        "https://nix-community.cachix.org?priority=2"
        "https://nix-gaming.cachix.org?priority=3"
        "https://cache.flox.dev?priority=4"
        "https://helix.cachix.org?priority=8"
        "https://yazi.cachix.org?priority=9"
        "https://devenv.cachix.org?priority=10"
        "https://nixpkgs-unfree.cachix.org?priority=11"
      ];
      trusted-public-keys = [
        "4rmcyt-matebook.cachix.org-1:OG8MqlfrDlyperVhYk2+va8Cwo/vE6tG/VbTlvq4I0I="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
        "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nqlt4="
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
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
    # fwupd.enable = true; # Removed, already in hardware-configuration.nix
    pcscd = {
      enable = true;
      plugins = [ pkgs.ccid ];
    };
    usbmuxd.enable = true;
    thermald.enable = true;
    power-profiles-daemon.enable = false; # Conflicts with auto-cpufreq

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
    # upower.enable = true; # Removed, already in hardware-configuration.nix
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
  users = {
    groups = {
      git = { };
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
    };
  };
  # =================================================================
  # 13. Virtualization (optional)
  # =================================================================
  virtualisation.podman.enable = true;
}
