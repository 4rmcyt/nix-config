{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/gaming
    ../../../modules/users/zeev
    ../../../modules/disko/desktop
    ../../../modules/base
  ];

  users.groups.git = { };
  users.users.git = {
    isSystemUser = true;
    group = "git";
    home = "/var/lib/git";
    createHome = true;
    shell = pkgs.zsh;
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  systemd.services.dlm.wantedBy = [ "multi-user.target" ];

  networking = {
    hostName = "desktop";
    hostId = "e134040f";
    networkmanager.enable = true;
    wireless.enable = false;
    firewall.enable = true;
    nameservers = [
      "45.90.28.0#Desktop-nextdns0.dns.nextdns.io"
      "45.90.30.0#Desktop-nextdns0.dns.nextdns.io"
    ];
  };

  # Time zone and locale
  time.timeZone = "America/Edmonton";
  i18n.defaultLocale = "en_US.UTF-8";

  # Group ALL services together
  services = {
    resolved = {
      enable = true;
      dnssec = "true";
      domains = [ "~." ];
      fallbackDns = [
        "45.90.28.0#Desktop-nextdns0.dns.nextdns.io"
        "45.90.30.0#Desktop-nextdns0.dns.nextdns.io"
      ];
      dnsovertls = "opportunistic";
    };

    tailscale.enable = true;

    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };

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

    openssh.enable = true;
    pcscd.enable = true;

    auto-cpufreq = {
      enable = true;
      settings = {
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };

    udev.packages = [ pkgs.yubikey-personalization ];

    power-profiles-daemon.enable = false;

    xserver.videoDrivers = [
      "nvidia"
      "displaylink"
    ];

    fwupd.enable = true;
  };

  # XDG portal for Plasma 6
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
    ];
  };

  security.rtkit.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    firefox
    discord
    htop
    toml-sort
    rustfmt
    neofetch
    nvtopPackages.nvidia
    tailscale
    helix
    telegram-desktop
    jellyfin-media-player
    direnv
    btop
    meslo-lgs-nf
    just
    just-lsp
    nixfmt
    treefmt
    nixfmt-rfc-style
    statix
    alejandra
    shfmt
    nixos-rebuild-ng
    yubikey-manager
    cachix
    chromium
    fwupd
    nix-fast-build
    nix-output-monitor
    zoxide
    powertop
    nvidia-vaapi-driver
    age
    nh
    displaylink
    xdg-desktop-portal-gtk
    unzip
    p7zip
    yubikey-manager
    yubioath-flutter

    # Devshell packages
    sops
    cmake-format
    nodePackages.prettier
    deadnix
    yamlfmt
    dockfmt
    nix-diff
    dockerfile-language-server
  ];

  # Nix settings
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
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "homeserver.cachix.org-1:0vStm6koDUwET/iWYhbKpsuVO4v3UgN3510zYH9YpZU="
        "4rmcyt.cachix.org-1:IzZEPOd8aKavFKw3BuUBAI/T93XUUWoS/n2M+LG65/0="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
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

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
  };

  # Enable home-manager backup for conflicting files
  home-manager.backupFileExtension = "hm-backup";

  system.stateVersion = "25.05";

  sops = {
    age.keyFile = "/root/.config/sops/age/keys.txt";
    # Optionally, enable secrets for activation
    # defaultSopsFile = ./secrets/common.yaml;
  };
}
