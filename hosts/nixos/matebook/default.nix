{
  pkgs,
  lib,
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
    # ../../../modules/networking/avahi

    # User configuration
    ../../../modules/users/zeev

    # GUI Applications
    ../../../modules/GUI/chrome
    ../../../modules/GUI/flatpak/hyprland
  ];

  # =================================================================
  # 3. Secrets Management
  # =================================================================
  sops.secrets = {
    tailscale_auth_key = {
      sopsFile = ../../../secrets/tailscale-matebook.yaml;
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
      systemd-boot.enable = false;
      limine = {
        enable = true;
        enableEditor = false;
        maxGenerations = 10;
        efiSupport = true;
        efiInstallAsRemovable = false;
        biosSupport = false;
        secureBoot.enable = true;
        style.wallpapers = [
          "${builtins.path {
            path = ./boot/background.jpg;
            name = "limine-background.jpg";
          }}"
        ];
      };
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

    pathsToLink = [
      "/share/icons"
      "/share/fonts"
    ];
    sessionVariables.XDG_DATA_DIRS = [
      "$HOME/.local/share/flatpak/exports/share"
      "/var/lib/flatpak/exports/share"
    ];

    systemPackages = with pkgs; [
      # =============================================================
      # Laptop-specific tools
      # =============================================================
      ansible
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

      #Lix tools
      lixPackageSets.latest.nixpkgs-review
      lixPackageSets.latest.nix-eval-jobs
      lixPackageSets.latest.nix-fast-build
      lixPackageSets.latest.colmena
      lixPackageSets.latest.nix-direnv
      lixPackageSets.latest.nix-serve-ng
      lixPackageSets.latest.boehmgc
      lixPackageSets.latest.nil
      lixPackageSets.latest.nurl
      lixPackageSets.latest.nix-init
      lixPackageSets.latest.nix-update

      # Secure Boot & EFI Tools
      efibootmgr
      ifrextractor-rs
      sbctl
      sbsigntool
      optnix
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

  # Override niri module default which adds xdg-desktop-portal-gnome (requires GNOME Shell)
  xdg.portal = {
    extraPortals = lib.mkForce [pkgs.xdg-desktop-portal-gtk];
    config.niri = lib.mkForce {
      default = ["gtk"];
      "org.freedesktop.impl.portal.Access" = ["gtk"];
      "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
      "org.freedesktop.impl.portal.Notification" = ["gtk"];
      "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
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
        "--accept-routes"
        "--reset"
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
