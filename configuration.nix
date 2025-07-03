{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    # Do NOT import ./home.nix here - it's handled by home-manager.users.zeev below
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable VSCode Server - ADD THIS ONE LINE
  services.vscode-server.enable = true;
  
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
    sops
    age
  ];

  # Users
  users.users.zeev = {
    isNormalUser = true;
    description = "zeev";
    extraGroups = [ "wheel" "networkmanager" ];
    hashedPasswordFile = config.sops.secrets.zeev_password.path;
    shell = pkgs.zsh;
  };

  # Enable zsh system-wide
  programs.zsh.enable = true;

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
    
    secrets = {
      zeev_password = { };
      # Add other secrets as needed
    };
  };

  # Home Manager configuration - THIS IS WHERE HOME.NIX GETS IMPORTED
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      zeev = import ./home.nix;  # This is the ONLY place home.nix should be imported
    };
  };

  system.stateVersion = "25.05";
}