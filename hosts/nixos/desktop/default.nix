{
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/hyprland
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

  services.scx.enable = true;

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
    neofetch
    nvtopPackages.nvidia
    tailscale
    helix_git
    telegram-desktop_git
    jellyfin-media-player
    direnv
    btop
    nixfmt
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
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
  };
  # Enable home-manager backup for conflicting files
  home-manager.backupFileExtension = "backup";

  system.stateVersion = "25.05";
}
