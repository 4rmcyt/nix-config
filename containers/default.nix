{ config, pkgs, ... }:

{
  virtualisation.oci-containers.containers = {
    tplink-exporter-living-room = {
      image = "thelastguardian/tplinkexporter"; # Use the full sha256 digest
      autoStart = true;
      networks =  [ "host" ];
      environmentFiles = [ config.sops.secrets.containers_env.path ];
    };

    tplink-exporter-office = {
      image = "thelastguardian/tplinkexporter"; # Use the full sha256 digest
      autoStart = true;
      networks =  [ "host" ];
      environmentFiles = [ config.sops.secrets.containers_env.path ];
    };

    nextdns-exporter = {
      image = "ghcr.io/raylas/nextdns-exporter:latest"; # Pin to a specific version, not :latest
      autoStart = true;
      networks =  [ "host" ];
      environmentFiles = [ config.sops.secrets.containers_env.path ];
    };
  };
}