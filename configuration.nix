{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable SSH - CRITICAL for remote access
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
    };
    openFirewall = true;
  };

  # User configuration
  users.users.zeev = {
    isNormalUser = true;
    description = "Zeev";
    extraGroups = [ "networkmanager" "wheel" ];
    password = "temppassword123";  # Change after installation
    shell = pkgs.bash;
  };

  # System packages
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    htop
    tmux
  ];

  # Completely disable SOPS for now
  # NO sops configuration at all

  # System configuration
  system.stateVersion = "23.11";
}