{ config, pkgs, ... }:
{
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = {
    tl-sg-prometheus-exporter = {
      image = "ghcr.io/mad-ady/tl-sg-prometheus-exporter:main";
      autoStart = true;
      networks = [ "podman" ];
      ports = [ "127.0.0.1:8000:8000" ];
      volumes = [
        "${config.sops.secrets.tplinkExporterConfig.path}:/app/config.yaml:ro"
      ];
    };

    nextdns-exporter = {
      image = "ghcr.io/raylas/nextdns-exporter";
      autoStart = true;
      networks = [ "podman" ];
      ports = [ "127.0.0.1:9948:9948" ];
      environmentFiles = [ config.sops.secrets.containers_env.path ];
    };
    hearing-aid = {
      image = "blampe/lidarr:latest";
      name = "hearing-aid";
      autoStart = true;
      networks = [ "podman" ];
      ports = [ "127.0.0.1:18686:18686" ];
    };
  };
}
