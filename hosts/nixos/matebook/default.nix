{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    # Hardware and system base
    ./hardware-configuration.nix
    ../../../modules/base
    ../../../modules/disko/matebook
    ../../../modules/options

    # Monitoring
    ../../../modules/monitoring/node-exporter-client.nix
    ../../../modules/monitoring/alloy-client.nix

    # Networking
    ../../../modules/networking/nfs-client
    ../../../modules/networking/ssh
    # not in use: ../../../modules/networking/avahi

    # User configuration
    ../../../modules/users/zeev

    # GUI Applications
    ../../../modules/GUI/chrome
    ../../../modules/GUI/flatpak
    ../../../modules/GUI/kdeconnect
    ../../../modules/GUI/nemo
  ];

  # Secrets Management
  sops.secrets = {
    tailscale_auth_key = {
      sopsFile = ../../../secrets/tailscale-matebook.yaml;
    };
    git_access_token = {
      sopsFile = ../../../secrets/common.yaml;
      key = "git_access_token";
    };
  };

  # Boot Configuration
  system.boot.loader.kernelFile = "bzImage";

  boot = {
    # Hibernation: swapfile lives on the ext4 root fs (see modules/disko/matebook).
    # resume_offset is the physical block offset of /swapfile and MUST be regenerated
    # any time the swapfile is recreated (e.g. after a fresh disko install):
    #   filefrag -v /swapfile | awk '$1=="0:" {print $4}' | tr -d '.'
    resumeDevice = config.fileSystems."/".device;
    kernelParams = ["resume_offset=63500288"];

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

  # Nix Configuration
  nix.settings = {
    cores = 0;
    max-jobs = "auto";
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  # Environment
  environment = {
    etc."polkit-1/actions/org.auto-cpufreq.pkexec.policy".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE policyconfig PUBLIC
       "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
       "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
      <policyconfig>
        <action id="org.auto-cpufreq.pkexec">
          <description>Run auto-cpufreq</description>
          <message>Authentication is required to run auto-cpufreq</message>
          <defaults>
            <allow_any>auth_admin</allow_any>
            <allow_inactive>auth_admin</allow_inactive>
            <allow_active>auth_admin_keep</allow_active>
          </defaults>
          <annotate key="org.freedesktop.policykit.exec.path">${pkgs.auto-cpufreq}/bin/auto-cpufreq</annotate>
          <annotate key="org.freedesktop.policykit.exec.allow_gui">false</annotate>
        </action>
      </policyconfig>
    '';
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
      # Laptop-specific tools
      ansible
      acpi
      brightnessctl
      powertop

      # Hardware Support & Monitoring
      fira-code
      fira-mono
      meslo-lgs-nf
      nerd-fonts.droid-sans-mono
      nerd-fonts.fira-code

      # Secure Boot & EFI Tools
      efibootmgr
      ifrextractor-rs
      sbctl
      sbsigntool
      optnix
    ];
  };

  # Fonts
  fonts.fontconfig.useEmbeddedBitmaps = true;

  # Home Manager
  # backupFileExtension is set in commonHomeManagerNixosConfig with unique timestamp

  my.nodeExporter.enable = true;
  my.alloyClient.enable = true;

  # Networking
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

  # Programs
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

  # Security
  security = {
    rtkit.enable = true;
    polkit.enable = true;
  };

  # suspend-then-hibernate: go to sleep first, hibernate after this long
  # (or sooner on low battery). See systemd-sleep.conf(5).
  systemd.sleep.settings.Sleep.HibernateDelaySec = "30m";

  # 5.8GB RAM leaves little headroom: default /sys/power/image_size (~2.2GB)
  # caused "PM: hibernation: Error -12 creating image" (not enough free pages
  # to preallocate the snapshot). image_size=0 makes the kernel swap out as
  # much as possible before snapshotting instead of preserving pages in RAM,
  # trading a slower resume for hibernation actually succeeding.
  systemd.tmpfiles.rules = ["w /sys/power/image_size - - - - 0"];

  # Services
  services = {
    # Audio Services
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

    # Display Manager - greetd + niri
    greetd = {
      enable = true;
      settings = {
        default_session = {
          # niri-session (not `niri --session`) imports the environment into
          # the systemd user session and starts niri.service, which is what
          # activates graphical-session.target. Without it, logind never
          # promotes the session past class=greeter, so anything gated on
          # graphical-session.target (xdg-desktop-portal, etc.) spins forever
          # with "Dependency failed for Portal service".
          command = "${pkgs.niri}/bin/niri-session";
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

    # File Systems & Storage
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

    # Hardware Services
    blueman.enable = true;

    pcscd = {
      enable = true;
      plugins = [pkgs.ccid];
    };

    fwupd.enable = true;

    udisks2.enable = true;
    usbmuxd.enable = true;

    # Power Management
    power-profiles-daemon.enable = false;

    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };

    # NB: logind.conf(5) keys are PascalCase (HandleLidSwitch, not lidSwitch) —
    # the previous lowercase keys were silently ignored by systemd-logind.
    logind.settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate";
      HandleLidSwitchDocked = "ignore";
    };

    # System Services
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
        "--accept-dns=true"
        "--reset"
        "--login-server=https://hs.${config.my.defaults.domain}"
      ];
      extraSetFlags = ["--operator=${config.my.defaults.user}"];
    };
  };

  # Users & Groups
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

  # Virtualization
  virtualisation.podman.enable = true;
}
