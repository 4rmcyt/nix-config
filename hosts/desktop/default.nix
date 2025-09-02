{
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

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_cachyos;
  };

  chaotic = {
    mesa-git.enable = true;
    scx.enable = true;
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

    # Chaotic Nyx packages
    inputs.chaotic.packages.${pkgs.system}.helix_git
    inputs.chaotic.packages.${pkgs.system}.nyxUtils
    inputs.chaotic.packages.${pkgs.system}.telegram-desktop_git
  ];

  # AMD CPU optimizations
  boot.kernelModules = [ "kvm-amd" ];

  system.stateVersion = "25.05";
}
