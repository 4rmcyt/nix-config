{ pkgs, ... }:
{
  # =================================================================
  # 1. Imports & Global Settings
  # =================================================================
  imports = [
    ./hardware-configuration.nix
    ../../../modules/gaming
    ../../../modules/users/zeev
    ../../../modules/disko/desktop
    ../../../modules/base
    ../../../modules/networking/tailscale
    ../../../modules/networking/dnssec
  ];

  # =================================================================
  # 2. System Configuration
  # =================================================================
  system.stateVersion = "25.05";

  # =================================================================
  # 3. User & Group Management
  # =================================================================
  users = {
    users = {
      prometheus = {
        isSystemUser = true;
        description = "Prometheus daemon user";
        group = "prometheus";
      };
      git = {
        isSystemUser = true;
        group = "git";
        description = "Git user";
        home = "/var/lib/git";
        createHome = true;
        shell = pkgs.zsh;
      };
    };
    groups = {
      git = { };
      prometheus = { };
    };
  };

  # =================================================================
  # 4. Bootloader & Secure Boot
  # =================================================================
  boot = {
    loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = true;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };

  # =================================================================
  # 5. Networking Configuration
  # =================================================================
  networking = {
    hostName = "desktop";
    hostId = "e134040f";
    networkmanager.enable = true;
    wireless.enable = false;
    dnssec = {
      enable = true;
      profileId = "nextdns0";
    };
    tailscaleAuth = {
      enable = true;
      sopsFile = ../../../secrets/tailscale-desktop.yaml;
      key = "tailscale_auth_key";
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [ 9100 ]; # Prometheus node exporter
    };
  };

  # =================================================================
  # 6. Time & Locale
  # =================================================================
  time.timeZone = "America/Edmonton";
  i18n.defaultLocale = "en_US.UTF-8";

  # =================================================================
  # 7. Hardware Configuration
  # =================================================================
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
  };

  # =================================================================
  # 8. Secrets Management with SOPS
  # =================================================================
  sops = {
    age.keyFile = "/root/.config/sops/age/keys.txt";
  };

  # =================================================================
  # 9. Nix Configuration
  # =================================================================
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      substituters = [
        "https://cache.nixos.org"
        "https://nixpkgs-wayland.cachix.org"
        "https://nix-community.cachix.org"
        "https://nix-gaming.cachix.org"
        "https://homeserver.cachix.org"
        "https://4rmcyt.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "homeserver.cachix.org-1:0vStm6koDUwET/iWYhbKpsuVO4v3UgN3510zYH9YpZU="
        "4rmcyt.cachix.org-1:IzZEPOd8aKavFKw3BuUBAI/T93XUUWoS/n2M+LG65/0="
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      fallback = true;
      system-features = [
        "big-parallel"
        "kvm"
      ];
      trusted-users = [ "zeev" ];
      warn-dirty = false;
      cores = 6;
      max-jobs = 6;
      show-trace = true;
      download-buffer-size = 1073741824;
    };
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  # =================================================================
  # 10. System Services
  # =================================================================
  services = {
    prometheus.exporters.node = {
      enable = true;
      port = 9100;
      enabledCollectors = [
        "systemd"
        "processes"
        "interrupts"
        "ksmd"
        "logind"
        "meminfo_numa"
        "mountstats"
        "network_route"
        "textfile"
        "vmstat"
        "zfs"
        "thermal_zone"
      ];
      listenAddress = "0.0.0.0";
    };
    # Desktop Environment - Plasma 6
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      autoNumlock = true;
      settings.General.DisplayServer = "wayland";
      theme = "sugar-dark";
      enableHidpi = true;
    };

    # Audio - PipeWire
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      lowLatency = {
        enable = true;
        quantum = 64;
        rate = 48000;
      };
    };

    # Hardware Support
    udev = {
      packages = with pkgs; [
        yubikey-personalization
        yubikey-manager
        yubioath-flutter
        via
        qmk
        qmk-udev-rules
        dfu-util
      ];
    };

    # System Services
    openssh.enable = true;
    pcscd.enable = true;
    fwupd.enable = true;

    # Power Management
    auto-cpufreq = {
      enable = true;
      settings = {
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };
    power-profiles-daemon.enable = false;

    # Graphics
    xserver.videoDrivers = [ "nvidia" ];
  };

  # =================================================================
  # 11. Security & XDG Configuration
  # =================================================================
  security.rtkit.enable = true;

  # XDG portal for Plasma 6
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
    ];
  };

  # =================================================================
  # 12. Programs Configuration
  # =================================================================
  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    zsh.enable = true;

    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 10d --keep 3";
      flake = "/home/zeev/src/nix-config";
    };
  };

  # Enable home-manager backup for conflicting files
  home-manager.backupFileExtension = "backup";

  # =================================================================
  # 13. System Packages
  # =================================================================
  environment.systemPackages = with pkgs; [
    # Secure Boot & EFI tools
    sbctl
    shim-unsigned
    ifrextractor-rs
    efitools
    efibootmgr
    sbsigntool
    uefitool

    # Core utilities
    vim
    wget
    curl
    git
    htop
    btop
    iotop
    lsof
    net-tools
    iproute2
    neofetch
    mc
    unzip
    p7zip
    usbutils
    openssl
    pass

    # Development tools
    helix
    direnv
    just
    just-lsp
    nixfmt
    treefmt
    nixfmt-rfc-style
    statix
    alejandra
    shfmt
    toml-sort
    rustfmt
    nixos-rebuild-ng
    cachix
    nix-fast-build
    nix-output-monitor
    nh
    zoxide
    age

    # DevShell packages
    sops
    cmake-format
    nodePackages.prettier
    deadnix
    yamlfmt
    dockfmt
    nix-diff
    dockerfile-language-server

    # Desktop applications
    firefox
    discord
    telegram-desktop
    jellyfin-media-player
    chromium

    # System monitoring
    nvtopPackages.nvidia
    powertop
    fwupd

    # Hardware support
    yubikey-manager
    yubioath-flutter
    via
    qmk
    qmk-udev-rules
    dfu-util

    # Fonts
    meslo-lgs-nf

    # Theme
    sddm-sugar-dark

    # Graphics
    nvidia-vaapi-driver
    xdg-desktop-portal-gtk

    # KDE Applications
    kdePackages.konsole
    kdePackages.kate
    kdePackages.ark
    kdePackages.okular
    kdePackages.gwenview
    kdePackages.spectacle
    kdePackages.kcalc
    kdePackages.kfind
    kdePackages.filelight
    kdePackages.partitionmanager
    kdePackages.discover
    kdePackages.kcharselect
    kdePackages.ksystemlog
    kdePackages.kclock
    kdePackages.sddm-kcm
    kdePackages.systemsettings
    kdePackages.signon-kwallet-extension
  ];

  systemd.user.tmpfiles.rules = [
    "d %h/.cache/mozilla 0755 zeev users 7d"
  ];
}
