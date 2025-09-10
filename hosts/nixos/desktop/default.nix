{ pkgs, ... }:
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

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_cachyos;
  };

  chaotic = {
    mesa-git.enable = true;
  };

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
  services.scx.enable = true;

  # Time zone and locale
  time.timeZone = "America/Edmonton";
  i18n.defaultLocale = "en_US.UTF-8";

  # Audio
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
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
  ];

  # Nix settings
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "zeev" ];
    };
  };

  system.stateVersion = "25.05";
}