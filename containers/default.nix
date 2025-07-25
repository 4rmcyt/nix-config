{ config, pkgs, ... }:
{
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = {
   tl-sg-prometheus-exporter = {
      image = "ghcr.io/mad-ady/tl-sg-prometheus-exporter:latest";
      autoStart = true;
      ports = [ "127.0.0.1:9266:8000" ];
      volumes = [
        "${tplinkExporterConfig}:/app/config.yml:ro"
      ];
    };

    nextdns-exporter = {
      image = "ghcr.io/raylas/nextdns-exporter"; 
      autoStart = true;
      networks =  [ "podman" ];
      ports = [ "127.0.0.1:9948:9948" ];
      environmentFiles = [ config.sops.secrets.containers_env.path ];
    };
  };
}