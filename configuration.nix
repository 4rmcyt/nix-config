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
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
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

  # User configuration with SOPS password
  users.users.zeev = {
    isNormalUser = true;
    description = "Zeev";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    hashedPasswordFile = config.sops.secrets.zeev_password.path;
    shell = pkgs.bash;
  };

  # System packages
  environment.systemPackages = with pkgs; [
    git vim wget curl htop tmux age sops openssh
  ];

  # Enable Home Manager
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      zeev = import ./home.nix;
    };
  };

  # Deluge BitTorrent with VPN routing
  services.deluge = {
    enable = true;
    web.enable = true;
    web.port = 8112;
    declarative = true;
    config = {
      daemon_port = 58846;
      listen_ports = [6881 6891];
      random_port = false;
      outgoing_ports = [0 0];
      allow_remote = true;
      download_location = "/var/lib/deluge/Downloads";
      torrentfiles_location = "/var/lib/deluge/Torrents";
    };
    authFile = pkgs.writeText "deluge-auth" ''
      localclient::10
      admin:password123:10
    '';
    openFirewall = false;
  };

  # Override systemd services for VPN routing
  systemd.services.deluged = {
    serviceConfig = {
      Type = lib.mkForce "simple";
      ExecStart = lib.mkForce "${pkgs.iproute2}/bin/ip netns exec pia ${pkgs.deluge}/bin/deluged --do-not-daemonize -c /var/lib/deluge/.config/deluge -l /var/lib/deluge/daemon.log -L info";
      PIDFile = lib.mkForce null;
      Restart = "always";
      RestartSec = "5";
      TimeoutStartSec = "30";
    };
    wants = ["deluge-vpn-routing.service"];
    after = ["deluge-vpn-routing.service" "network.target"];
  };

  systemd.services.deluge-web = {
    serviceConfig = {
      Type = lib.mkForce "simple";
      ExecStart = lib.mkForce "${pkgs.deluge}/bin/deluge-web --do-not-daemonize -c /var/lib/deluge/.config/deluge -l /var/lib/deluge/web.log -L info";
      PIDFile = lib.mkForce null;
      Restart = "always";
      RestartSec = "5";
      TimeoutStartSec = "30";
    };
    wants = ["deluged.service"];
    after = ["deluged.service" "network.target"];
  };

  system.stateVersion = "25.05";
}
