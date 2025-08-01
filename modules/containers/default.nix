{ config, pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.podman
    pkgs.podman-compose
    pkgs.podman-tui
  ];

  sops.secrets.containers_env = {
    sopsFile = ../../secrets/.env;
    owner = "root";
    group = "root";
    mode = "0400";
    format = "dotenv";
  };
  
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = {
    # tl-sg-prometheus-exporter = {
    #   image = "ghcr.io/mad-ady/tl-sg-prometheus-exporter:main";
    #   autoStart = true;
    #   networks = [ "podman" ];
    #   ports = [ "127.0.0.1:8000:8000" ];
    #   volumes = [
    #     "${config.sops.secrets.tplinkExporterConfig.path}:/app/config.yaml:ro"
    #   ];
    # };
    nextdns-exporter = {
      image = "ghcr.io/raylas/nextdns-exporter";
      user = "podman:podman";
      autoStart = true;
      networks = [ "podman" ];
      ports = [ "127.0.0.1:9948:9948" ];
      environmentFiles = [ config.sops.secrets.containers_env.path ];
    };
    portainer = {
      image = "ghcr.io/portainer/portainer-ce:latest";
      autoStart = true;
      networks = [ "podman" ];
      ports = [ "127.0.0.1:9000:9000" ];
      environmentFiles = [ config.sops.secrets.containers_env.path ];
    };
  };

  networking.firewall.allowedTCPPorts = [
    # Podman
    2375 # Podman API (insecure, for local use only)
    2376 # Podman API (secure, for local use only)
    9948 # NextDNS Exporter
    9000 # Portainer
  ];
  networking.firewall.allowedUDPPorts = [
    # Podman
    2375 # Podman API (insecure, for local use only)
    2376 # Podman API (secure, for local use only)
  ];
  users.users.podman = {
    isSystemUser = true;
    group = "podman";
    extraGroups = [
      "users"
      "podman"
    ];
  };
  users.groups.podman = { };
  users.extraGroups.podman.members = [
    "zeev"
    "uptime-kuma"
    "podman"
  ];

}
