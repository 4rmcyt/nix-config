{ config, pkgs, ... }:

{
  virtualisation.oci-containers.containers = {
    backend = "podman"; 
    tplink-exporter-living-room = {
      image = "thelastguardian/tplinkexporter"; # Use the full sha256 digest
      autoStart = true;
      networks =  [ "host" ];
      ports = [
        {
          "127.0.0.1:9266:9266"
        }
      ];
      environmentFiles = [ config.sops.secrets.containers_env.path ];
    };

    tplink-exporter-office = {
      image = "thelastguardian/tplinkexporter"; # Use the full sha256 digest
      autoStart = true;
      networks =  [ "host" ];
      ports = [
        {
          "127.0.0.1:9267:9267"
        }
      ];
      environmentFiles = [ config.sops.secrets.containers_env.path ];
    };

    nextdns-exporter = {
      image = "ghcr.io/raylas/nextdns-exporter:latest"; # Pin to a specific version, not :latest
      autoStart = true;
      networks =  [ "host" ];
      ports = [
        {
          "127.0.0.1:9790:9790"
        }
      ];
      environmentFiles = [ config.sops.secrets.containers_env.path ];
    };
  };
}