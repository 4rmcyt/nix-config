{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./services/deluge-vpn.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
      X11Forwarding = false;
      MaxAuthTries = 3;
      LoginGraceTime = 30;
    };
    openFirewall = true;
  };

  # SOPS configuration
  sops.defaultSopsFile = ./secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";

  # Define all secrets
  sops.secrets.zeev_password = {
    neededForUsers = true;
  };
  sops.secrets.nextcloud_admin_password = {};
  sops.secrets.microbin_admin_password = {};
  sops.secrets.tailscale_auth_key = {};
  sops.secrets.hass_postgres_password = {
    owner = "hass";
    group = "hass";
    mode = "0400";
  };
  # Add missing Mosquitto secret
  sops.secrets.mosquitto_iotdevice_password = {
    owner = "mosquitto";
    group = "mosquitto";
    mode = "0400";
  };

  # User configuration with SOPS password
  users.users.zeev = {
    isNormalUser = true;
    description = "Zeev";
    extraGroups = [ "networkmanager" "wheel" "docker" "media" ];
    hashedPasswordFile = config.sops.secrets.zeev_password.path;
    shell = pkgs.bash;
  };

  # Define groups
  users.groups = {
    media = {};
    microbin = {};
    miniflux = {};
    samba = {};
  };

  # Define system users for services that need them
  users.users = {
    microbin = {
      isSystemUser = true;
      group = "microbin";
      extraGroups = [ "media" ];
    };
    miniflux = {
      isSystemUser = true;
      group = "miniflux";
      extraGroups = [ "media" ];
    };
    samba = {
      isSystemUser = true;
      group = "samba";
      extraGroups = [ "media" ];
    };
  };

  # Add existing service users to media group
  users.users.jellyfin.extraGroups = [ "media" ];
  users.users.deluge.extraGroups = [ "media" ];
  users.users.nextcloud.extraGroups = [ "media" ];
  users.users.radicale.extraGroups = [ "media" ];
  users.users.audiobookshelf.extraGroups = [ "media" ];
  users.users.paperless.extraGroups = [ "media" ];

  systemd.tmpfiles.rules = [
    "d /home/zeev/media 0770 zeev media -"
    "d /home/zeev/media/audiobooks 0770 zeev media -"
    "d /home/zeev/media/movies 0770 zeev media -"
    "d /home/zeev/media/tv 0770 zeev media -"
    "d /home/zeev/media/series 0770 zeev media -"
    "d /home/zeev/media/music 0770 zeev media -"
    "d /home/zeev/media/other 0770 zeev media -"
    "d /home/zeev/media/podcasts 0770 audiobookshelf media -"
    "d /home/zeev/Downloads 0770 deluge deluge -"
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    git vim wget curl jq htop btop age sops openssh lsof neovim mc apacheHttpd wireguard-tools iproute2
  ];

  # Enable Home Manager
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      zeev = import ./home.nix;
    };
  };

  # Disable built-in Deluge service - using custom VPN version
  services.deluge.enable = false;

  # Disable nginx service
  services.vscode-server.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.05";
}