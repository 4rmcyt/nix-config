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
  # 2. Boot Configuration
  # =================================================================
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = false;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };

  # =================================================================
  # 3. Environment
  # =================================================================
  environment = {
    sessionVariables.NIXOS_OZONE_WL = "1";
    systemPackages = with pkgs; [
      # Core utilities
      btop
      curl
      git
      htop
      libdbusmenu
      libva-utils
      mc
      neofetch
      openssl
      p7zip
      pciutils
      unzip
      usbutils
      vim
      wget

      # Development tools
      age
      alejandra
      cachix
      cmake-format
      deadnix
      direnv
      dockfmt
      dockerfile-language-server
      gnumake
      helix
      just
      just-lsp
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
      zoxide

      # Desktop applications
      # jellyfin-media-player
      jellyfin-mpv-shim
      telegram-desktop

      # Fonts & Themes
      fira-code
      fira-mono
      meslo-lgs-nf
      nerd-fonts.droid-sans-mono
      nerd-fonts.fira-code
      sddm-astronaut
      sddm-sugar-dark

      # Graphics
      nvidia-vaapi-driver
      xdg-desktop-portal-gtk

      # Hardware support
      apcupsd
      openrgb-with-all-plugins
      yubico-pam
      yubikey-manager
      yubioath-flutter
      ryzen-monitor-ng
      microcode-amd

      # KDE Applications
      kdePackages.ark
      kdePackages.discover
      kdePackages.filelight
      kdePackages.gwenview
      kdePackages.kclock
      kdePackages.kate
      kdePackages.kcalc
      kdePackages.kcharselect
      kdePackages.kfind
      kdePackages.kio-extras
      kdePackages.konsole
      kdePackages.ksystemlog
      kdePackages.okular
      kdePackages.partitionmanager
      kdePackages.plasma-browser-integration
      kdePackages.qtmultimedia
      kdePackages.qtsvg
      kdePackages.qtwebengine
      kdePackages.sddm-kcm
      kdePackages.signon-kwallet-extension
      kdePackages.spectacle
      kdePackages.systemsettings
      kwalletcli

      # Security & Encryption
      (pass.withExtensions (exts: [
        exts.pass-checkup
        exts.pass-file
        exts.pass-genphrase
        exts.pass-import
        exts.pass-otp
        exts.pass-update
      ]))
      pinentry-curses

      # Secure Boot & EFI tools
      efibootmgr
      efitools
      ifrextractor-rs
      sbctl
      sbsigntool
      shim-unsigned
      uefitool

      # System monitoring
      cifs-utils
      fwupd
      nvtopPackages.nvidia
      powertop
      samba

      # Commented out due to CMake compatibility issues
      # dfu-util
      # qmk
      # qmk-udev-rules
      # via
    ];
  };

  # =================================================================
  # 4. Fonts
  # =================================================================
  fonts.fontconfig.useEmbeddedBitmaps = true;

  # =================================================================
  # 5. Home Manager
  # =================================================================
  home-manager.backupFileExtension = "backup";

  # =================================================================
  # 6. Internationalization & Time
  # =================================================================
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Edmonton";

  # =================================================================
  # 7. Networking
  # =================================================================
  networking = {
    dnssec = {
      enable = true;
      profileId = "nextdns0";
    };
    enableIPv6 = false;
    firewall = {
      allowedTCPPorts = [ 9100 ]; # Prometheus node exporter
      enable = true;
    };
    hostId = "e134040f";
    hostName = "desktop";
    networkmanager.enable = true;
    tailscaleAuth = {
      enable = true;
      key = "tailscale_auth_key";
      sopsFile = ../../../secrets/tailscale-desktop.yaml;
    };
    wireless.enable = false;
  };

  # =================================================================
  # 8. Nix Configuration
  # =================================================================
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      cores = 12;
      download-buffer-size = 1073741824;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      fallback = true;
      max-jobs = 12;
      show-trace = true;
      substituters = [
        "https://cache.nixos.org"
        "https://4rmcyt.cachix.org"
        "https://nix-gaming.cachix.org"
        "https://cuda-maintainers.cachix.org"
        "https://nix-community.cachix.org"
      ];
      system-features = [
        "big-parallel"
        "kvm"
        "gccarch-znver4"
        "benchmark"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "4rmcyt.cachix.org-1:IzZEPOd8aKavFKw3BuUBAI/T93XUUWoS/n2M+LG65/0="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
      trusted-users = [ "zeev" ];
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
    zsh.enable = true;
    # vscode.enable = true;
  };

  # =================================================================
  # 10. Security
  # =================================================================
  security.rtkit.enable = true;

  # =================================================================
  # 11. Secrets Management
  # =================================================================
  sops.age.keyFile = "/root/.config/sops/age/keys.txt";

  # =================================================================
  # 12. Services
  # =================================================================
  services = {
    # Audio - PipeWire
    pipewire = {
      alsa.enable = true;
      alsa.support32Bit = true;
      enable = true;
      lowLatency = {
        enable = true;
        quantum = 64;
        rate = 48000;
      };
      pulse.enable = true;
    };
    pulseaudio.enable = false;

    # Desktop Environment
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      autoNumlock = true;
      enable = true;
      enableHidpi = true;
      settings.General.DisplayServer = "wayland";
      theme = "breeze";
      wayland.compositor = "kwin";
      wayland.enable = true;
    };

    # auto-epp.enable = true;

    # Hardware & Peripherals
    udev = {
      extraRules = ''
        # Fix QMK udev rules - ensure proper permissions
        SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ff4", MODE="0666", GROUP="plugdev"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ffb", MODE="0666", GROUP="plugdev"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="174c", ATTRS{idProduct}=="2074", MODE="0666", GROUP="plugdev"
        SUBSYSTEM=="input", ATTRS{name}=="Rapoo Rapoo Gaming Device", TAG+="uaccess"
      '';
      packages = with pkgs; [
        yubioath-flutter
        yubikey-manager
        yubikey-personalization
        # dfu-util
        # qmk
        # qmk-udev-rules
        # via
      ];
    };

    # Monitoring
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

    # Power Management
    auto-cpufreq = {
      enable = true;
      settings.charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
    power-profiles-daemon.enable = false;

    # System Services
    flatpak.enable = true;
    fwupd.enable = true;
    openssh.enable = true;
    pcscd.enable = true;

    # X Server (disabled but configured for NVIDIA)
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      xkb.layout = "us";
    };
  };

  # =================================================================
  # 13. System State
  # =================================================================
  system.stateVersion = "25.05";

  # =================================================================
  # 14. Users & Groups
  # =================================================================
  users = {
    groups = {
      git = { };
      plugdev = { };
      prometheus = { };
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
      prometheus = {
        description = "Prometheus daemon user";
        group = "prometheus";
        isSystemUser = true;
      };
    };
  };

  # =================================================================
  # 15. Virtualization
  # =================================================================
  virtualisation.podman.enable = true;

  # =================================================================
  # 16. XDG Portal
  # =================================================================
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
    ];
  };
}
