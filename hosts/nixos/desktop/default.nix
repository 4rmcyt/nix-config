{ pkgs, ... }:
{
  # =================================================================
  # 1. Imports
  # =================================================================
  imports = [
    ./hardware-configuration.nix
    ../../../modules/base
    ../../../modules/disko/desktop
    ../../../modules/gaming
    ../../../modules/networking/dnssec
    ../../../modules/networking/tailscale
    ../../../modules/users/zeev
    # ../../../modules/GUI/ollama
    ../../../modules/GUI/OBS
  ];

  # =================================================================
  # 2. System Configuration
  # =================================================================
  system.stateVersion = "25.05";

  # =================================================================
  # 3. Internationalization & Time
  # =================================================================
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Edmonton";

  # =================================================================
  # 4. Boot Configuration
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
  # 5. Networking
  # =================================================================
  networking = {
    hostName = "desktop";
    hostId = "e134040f";
    enableIPv6 = false;
    networkmanager.enable = true;
    wireless.enable = false;
    dnssec = {
      enable = true;
      profileId = "2bffa2";
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
  # 6. Users & Groups
  # =================================================================
  users = {
    users = {
      git = {
        isSystemUser = true;
        group = "git";
        description = "Git user";
        home = "/var/lib/git";
        createHome = true;
        shell = pkgs.zsh;
      };
      prometheus = {
        isSystemUser = true;
        description = "Prometheus daemon user";
        group = "prometheus";
      };
    };
    groups = {
      git = { };
      prometheus = { };
      plugdev = { };
    };
  };

  # =================================================================
  # 7. Environment Variables
  # =================================================================
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # =================================================================
  # 8. Secrets Management
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
        "https://nix-community.cachix.org"
        "https://nix-gaming.cachix.org"
        "https://4rmcyt.cachix.org"
        "https://cuda-maintainers.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "4rmcyt.cachix.org-1:IzZEPOd8aKavFKw3BuUBAI/T93XUUWoS/n2M+LG65/0="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
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
  };

  # =================================================================
  # 10. Security
  # =================================================================
  security.rtkit.enable = true;

  # =================================================================
  # 11. Services
  # =================================================================
  services = {
    # Desktop Environment
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      wayland.compositor = "kwin";
      autoNumlock = true;
      settings.General.DisplayServer = "wayland";
      theme = "sddm-sugar-dark-theme";
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

    # Hardware & Peripherals
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
      extraRules = ''
        # Fix QMK udev rules - ensure proper permissions
        SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ff4", MODE="0666", GROUP="plugdev"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ffb", MODE="0666", GROUP="plugdev"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="174c", ATTRS{idProduct}=="2074", MODE="0666", GROUP="plugdev"
        SUBSYSTEM=="input", ATTRS{name}=="Rapoo Rapoo Gaming Device", TAG+="uaccess"
      '';
    };

    # System Services
    openssh.enable = true;
    pcscd.enable = true;
    fwupd.enable = true;
    flatpak.enable = true;

    # Monitoring
    prometheus.exporters.node = {
      enable = true;
      port = 9100;
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
    };

    # X Server (disabled but configured for NVIDIA)
    xserver.enable = false;
    xserver.videoDrivers = [ "nvidia" ];
    xserver.xkb.layout = "us";
  };

  # =================================================================
  # 12. XDG Portal
  # =================================================================
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
    ];
  };

  # =================================================================
  # 13. Programs
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

  # =================================================================
  # 14. Home Manager
  # =================================================================
  home-manager.backupFileExtension = "backup";

  # =================================================================
  # 15. System Packages
  # =================================================================
  environment.systemPackages = with pkgs; [
    # Core utilities
    vim
    wget
    curl
    git
    htop
    btop
    neofetch
    mc
    unzip
    p7zip
    usbutils
    openssl
    libdbusmenu
    pciutils

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
    gnumake

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
    telegram-desktop
    jellyfin-media-player
    chromium

    # System monitoring
    nvtopPackages.nvidia
    powertop
    fwupd
    cifs-utils
    samba

    # Hardware support
    yubikey-manager
    yubico-pam
    yubioath-flutter
    via
    qmk
    qmk-udev-rules
    dfu-util
    openrgb-with-all-plugins

    # Secure Boot & EFI tools
    sbctl
    shim-unsigned
    ifrextractor-rs
    efitools
    efibootmgr
    sbsigntool
    uefitool

    # Graphics
    nvidia-vaapi-driver
    xdg-desktop-portal-gtk

    # Fonts & Themes
    meslo-lgs-nf
    sddm-astronaut
    sddm-sugar-dark

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
    kdePackages.qtsvg
    kdePackages.qtmultimedia
    kdePackages.kio-extras
    kdePackages.plasma-browser-integration
    (pass.withExtensions (exts: [
      exts.pass-otp
      exts.pass-import
      exts.pass-checkup
      exts.pass-genphrase
      exts.pass-file
      exts.pass-update
    ]))
  ];

  virtualisation.podman.enable = true;
}
