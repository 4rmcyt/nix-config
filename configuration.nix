{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable VSCode Server
  services.vscode-server.enable = true;

  # User configuration
  users.users.zeev = {
    isNormalUser = true;
    description = "Zeev";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    hashedPasswordFile = config.sops.secrets.zeev_password.path;  # Fixed: use hashedPasswordFile
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

  # Enable Home Manager with inputs passed
  home-manager = {
    extraSpecialArgs = { inherit inputs; };  # Pass inputs to home-manager
    users = {
      zeev = import ./home.nix;
    };
  };

  # SOPS configuration
  sops.defaultSopsFile = ./secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
  
  sops.secrets.zeev_password = {
    neededForUsers = true;
  };

  # System configuration
  system.stateVersion = "25.05";
}