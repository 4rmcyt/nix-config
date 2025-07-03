{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable SSH - ADDED
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";  # Allow root login during setup
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
    };
    openFirewall = true;
  };

  # Enable VSCode Server
  services.vscode-server.enable = true;

  # User configuration
  users.users.zeev = {
    isNormalUser = true;
    description = "Zeev";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    # Temporarily use a plain password until SOPS is working
    password = "temppassword123";  # Change this after fixing SOPS
    shell = pkgs.bash;
    createHome = true;
    home = "/home/zeev";
  };

  # System packages
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    htop
    tmux
    age
    sops
  ];

  # Enable Home Manager with inputs passed
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      zeev = import ./home.nix;
    };
  };

  # TEMPORARILY DISABLE SOPS until we fix the encryption
  # sops.defaultSopsFile = ./secrets.yaml;
  # sops.defaultSopsFormat = "yaml";
  # sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
  # sops.age.generateKey = true;
  # sops.secrets.zeev_password = {
  #   neededForUsers = true;
  # };

  # System configuration
  system.stateVersion = "25.05";
}