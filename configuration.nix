{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
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

  services.pia-vpn = {
    enable = true;
    environmentFile = config.sops.secrets.pia_credentials.path;
    certificateFile = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/pia-foss/manual-connections/master/ca.rsa.4096.crt";
      sha256 = "sha256-Mumx0UM+qXYU8qFMbjWOP1fAVwzJ9rLugSaZumlsZqs=";
    };
    portForward.enable = true;
    maxLatency = 18.0;
  };

  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    settings = {
      "download-dir" = "/home/zeev/Downloads";
      "rpc-bind-address" = "0.0.0.0";
      "rpc-whitelist-enabled" = "false"; 
      "rpc-whitelist" = "127.0.0.1,192.168.1.*,100.64.0.*,localhost";
    };
    vpn.enable = true;
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
  sops.secrets.pia_credentials = {};

  # Define groups first
  users.groups = {
    media = {};
    microbin = {};
    miniflux = {};
    samba = {};
    kavita = {};
  };

  # User configuration
  users.users = {
    # Main user
    zeev = {
      isNormalUser = true;
      description = "Zeev";
      extraGroups = [ "networkmanager" "wheel" "docker" "media" "samba"];
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

    transmission = {
      isSystemUser = true;
      group = "transmission";
      extraGroups = [ "media" ];
    };

    kavita = {
      isSystemUser = true;
      group = "kavita";
      extraGroups = [ "media" ];
    };
  };

  # Add existing service users to media group where needed
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
    "d /home/zeev/library 0775 zeev media -"
    "d /home/zeev/library/books 0775 zeev media -"
    "d /home/zeev/library/comics 0775 zeev media -"
    "d /home/zeev/library/manga 0775 zeev media -"
    # Download directory
    "d /home/zeev/Downloads 0770 zeev media -" # This rule will need to be aligned with the new download-dir for Transmission
  ];

  # CENTRALIZED: Base system packages (service-specific tools in their files)
  environment.systemPackages = with pkgs; [
    # Essential system tools
    git vim wget curl jq age sops openssh neovim mc

    # Network tools
    wireguard-tools iproute2

    # Web server tools
    apacheHttpd # Note: you previously said you don't use Nginx, but apacheHttpd is here.
                # If you're not using it, consider removing.

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

  # Enable VSCode server
  services.vscode-server.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.05";
}