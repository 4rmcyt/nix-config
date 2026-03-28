{
  pkgs,
  config,
  ...
}: {
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
    ../../../modules/networking/nfs-client
    ../../../modules/networking/ssh
    ../../../modules/networking/avahi

    # User configuration
    ../../../modules/users/zeev

    # GUI Applications
    ../../../modules/GUI/chromium
  ];

  # =================================================================
  # 3. Secrets Management
  # =================================================================
  sops.secrets = {
    tailscale_auth_key = {
      sopsFile = ../../../secrets/headscale-matebook.yaml;
      key = "preauth_key";
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
  nix.settings = {
    cores = 0;
    max-jobs = "auto";
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  # =================================================================
  # 6. Environment
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
      # Laptop-specific tools
      # =============================================================
      acpi
      brightnessctl
      powertop

      # =============================================================
      # Hardware Support & Monitoring
      # =============================================================
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
  # backupFileExtension is set in commonHomeManagerNixosConfig with unique timestamp

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
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-qt;
    };

    niri = {
      enable = true;
      package = pkgs.niri;
    };
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
    # Display Manager - greetd + niri
    # =============================================================
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.niri}/bin/niri --session";
          user = "zeev";
        };
      };
    };

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

    fwupd.enable = true;

    thermald.enable = true;

    udisks2.enable = true;
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
      extraUpFlags = [
        "--login-server"
        "https://head.example.com"
        "--accept-routes"
      ];
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
