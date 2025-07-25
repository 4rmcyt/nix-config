{ config, pkgs, ... }:
{
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = {
    tplink-exporter-living-room = {
      image = "thelastguardian/tplinkexporter";
      networks =  [ "podman" ];
      ports = [ "127.0.0.1:9266:9717" ];
      cmd = [
        "--host=192.168.1.101" "--username=admin" "--password=sw2_SeptuagintA"
      ];
    };

    tplink-exporter-office = {
      image = "thelastguardian/tplinkexporter";
      autoStart = true;
      networks =  [ "podman" ];
      ports = [ "127.0.0.1:9267:9717" ];
      cmd = [
        "--host=192.168.1.100" "--username=admin" "--password=sw1_SeptuagintA"
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