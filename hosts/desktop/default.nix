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

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_6_12;
  };

  # Networking
  networking = {
    hostName = "desktop";
    hostId = "8425e349"; # Generate with: head -c 8 /etc/machine-id
    networkmanager.enable = true;
    firewall.enable = true;
  };

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
  ];

  # AMD CPU optimizations
  boot.kernelModules = [ "kvm-amd" ];

  system.stateVersion = "25.05";
}