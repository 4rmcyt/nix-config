{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/hyprland
    ../../modules/gaming
    ../../modules/users/zeev
  ];

  # Boot configuration with CachyOS kernel
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_cachyos;
  };

  # Networking with WiFi support
  networking = {
    hostName = "desktop";
    hostId = "8425e349"; # Generate with: head -c 8 /etc/machine-id
    networkmanager.enable = true;
    wireless.enable = false; # Disabled because we use NetworkManager
    firewall.enable = true;
  };

  # Tailscale
  services.tailscale.enable = true;

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
    jack.enable = true;
  };

  # Security
  security.rtkit.enable = true;

  # SSH
  services.openssh.enable = true;

  # System packages
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
  ];

  # AMD CPU optimizations
  boot.kernelModules = [ "kvm-amd" ];

  system.stateVersion = "25.05";
}