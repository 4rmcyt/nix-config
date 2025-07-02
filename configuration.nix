{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./disko.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
    tree
    unzip
  ];

  # Users
  users.users.zeev = {
    isNormalUser = true;
    description = "zeev";
    extraGroups = [ "wheel" "networkmanager" ];
    hashedPassword = "$y$j9T$jEo/iEqN827Jzqa0dtndo1$xoCk/8WqZ/v.JaCV0gj1Tr9Km/dVB9qKfKGn9/hjmk2";
  };

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Sops configuration
  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
  };

  # Home Manager
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      zeev = import ./home.nix;  # This imports your home.nix as a Home Manager config
    };
  };

  users.users.zeev.shell = pkgs.zsh;
  programs.zsh.enable = true;
  system.stateVersion = "25.05";
}