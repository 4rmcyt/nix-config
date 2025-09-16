{ pkgs, ... }:
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
    shell = pkgs.bash;
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "desktop";
    hostId = "e134040f";
    networkmanager.enable = true;
    wireless.enable = false;
    firewall.enable = true;
  };

  # Time zone and locale
  time.timeZone = "America/Edmonton";
  i18n.defaultLocale = "en_US.UTF-8";

  # Group ALL services together
  services = {
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

    xserver.videoDrivers = [ "nvidia" ];

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
    yubioath-flutter
    cachix
    chromium
    fwupd
    nix-fast-build
    nix-output-monitor
    zoxide
    powertop
    nvidia-vaapi-driver
    age

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
}
