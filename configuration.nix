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

  # CLEANED: Only central secrets (removed service-specific duplicates)
  sops.secrets.zeev_password = {
    neededForUsers = true;
  };
  sops.secrets.nextcloud_admin_password = {};
  sops.secrets.microbin_admin_password = {};
  sops.secrets.tailscale_auth_key = {};

  # REMOVED: Service-specific secrets moved to their respective files
  # - mosquitto_iotdevice_password (moved to mosquitto.nix)
  # - hass_postgres_password (moved to home-assistant.nix)
  # - pia_username, pia_password (moved to deluge-vpn.nix)

  # Define groups first
  users.groups = {
    media = {};
    microbin = {};
    miniflux = {};
    samba = {};
  };

  # User configuration
  users.users = {
    # Main user
    zeev = {
      isNormalUser = true;
      description = "Zeev";
      extraGroups = [ "networkmanager" "wheel" "docker" "media" ];
      hashedPasswordFile = config.sops.secrets.zeev_password.path;
      shell = pkgs.bash;
    };

    # System users for services
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

  # Add existing service users to media group where needed
  users.users.deluge.extraGroups = [ "media" ];
  users.users.nextcloud.extraGroups = [ "media" ];
  users.users.radicale.extraGroups = [ "media" ];
  users.users.paperless.extraGroups = [ "media" ];

  # CENTRALIZED: Media directory structure (moved from individual services)
  systemd.tmpfiles.rules = [
    # Base media directory
    "d /home/zeev/media 0770 zeev media -"

    # Media subdirectories with consistent permissions
    "d /home/zeev/media/audiobooks 0770 zeev media -"
    "d /home/zeev/media/podcasts 0770 zeev media -"
    "d /home/zeev/media/movies 0770 zeev media -"
    "d /home/zeev/media/tv 0770 zeev media -"
    "d /home/zeev/media/series 0770 zeev media -"
    "d /home/zeev/media/music 0770 zeev media -"
    "d /home/zeev/media/other 0770 zeev media -"

    # Download directory
    "d /home/zeev/Downloads 0770 deluge deluge -"
  ];

  # CENTRALIZED: Base system packages (service-specific tools in their files)
  environment.systemPackages = with pkgs; [
    # Essential system tools
    git vim wget curl jq age sops openssh neovim mc

    # Network tools
    wireguard-tools iproute2

    # Web server tools
    apacheHttpd

    # Basic monitoring (NO advanced tools - those are in monitoring.nix)
    htop btop lsof
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

  # Enable VSCode server
  services.vscode-server.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.05";
}