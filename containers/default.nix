{ config, pkgs, ... }:
{ 
  environment.systemPackages = [
      pkgs.podman
      pkgs.podman-compose
      pkgs.podman-tui
  ];

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
      podman.user = "podman:podman";
      autoStart = true;
      networks = [ "podman" ];
      ports = [ "127.0.0.1:9948:9948" ];
      environmentFiles = [ config.sops.secrets.containers_env.path ];
    };
    
  };
  users.users.podman = {
    isSystemUser = true;
    group = "podman";
    extraGroups = [ "users" "podman" ];
  };
  users.groups.podman = {  };
}
