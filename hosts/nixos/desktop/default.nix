{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/gaming
    ../../../modules/users/zeev
    ../../../modules/disko/desktop
    ../../../modules/base
  ];

  # Add the missing git group
  users.groups.git = { };
  users.users.git = {
    isSystemUser = true;
    group = "git";
    home = "/var/lib/git";
    createHome = true;
    shell = pkgs.bash;
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "qtwebengine-5.15.19" # Replace with the specific version
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # chaotic.mesa-git.enable = true;

  # services.scx.enable = true;

  # Networking with WiFi support
  networking = {
    hostName = "desktop";
    hostId = "e134040f";
    networkmanager.enable = true;
    wireless.enable = false;
    firewall.enable = true;
  };

  # Tailscale
  services.tailscale.enable = true;

  # Time zone and locale
  time.timeZone = "America/Edmonton";
  i18n.defaultLocale = "en_US.UTF-8";

  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # XDG portal for Plasma 6
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
    ];
  };
  # Audio
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    lowLatency = {
      # enable this module
      enable = true;
      # defaults (no need to be set unless modified)
      quantum = 64;
      rate = 48000;
    };
  };

  security.rtkit.enable = true;
  services.openssh.enable = true;

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
    just
    just-lsp
    nixfmt
    treefmt
    nixfmt-rfc-style
    statix
    alejandra
    deadnix
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
    hercules-ci-agent
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

  # systemd.services.displaylink-server = {
  #   enable = true;
  #   # Ensure it starts after udev has done its work
  #   requires = [ "systemd-udevd.service" ];
  #   after = [ "systemd-udevd.service" ];
  #   wantedBy = [ "multi-user.target" ]; # Start at boot
  #   # *** THIS IS THE CRITICAL 'serviceConfig' BLOCK ***
  #   serviceConfig = {
  #     Type = "simple"; # Or "forking" if it forks (simple is common for daemons)
  #     # The ExecStart path points to the DisplayLinkManager binary provided by the package
  #     ExecStart = "${pkgs.displaylink}/bin/DisplayLinkManager";
  #     # User and Group to run the service as (root is common for this type of daemon)
  #     User = "root";
  #     Group = "root";
  #     # Environment variables that the service itself might need
  #     # Environment = [ "DISPLAY=:0" ]; # Might be needed in some cases, but generally not for this
  #     Restart = "on-failure";
  #     RestartSec = 5; # Wait 5 seconds before restarting
  #   };
  # };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
  };

  services.hercules-ci-agent.enable = true;
  services.fwupd.enable = true;
  # Enable home-manager backup for conflicting files
  home-manager.backupFileExtension = "backup";

  system.stateVersion = "25.05";
}
