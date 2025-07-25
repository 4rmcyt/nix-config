{ config, pkgs, ... }:
let 
  tplink_office_ip = builtins.readFile config.sops.secrets.tplink_office_ip.path;
  tplink_living_room_ip = builtins.readFile config.sops.secrets.tplink_living_room_ip.path;
  tplink_office_password = builtins.readFile config.sops.secrets.tplink_office_password.path;
  tplink_living_room_password = builtins.readFile config.sops.secrets.tplink_living_room_password.path;
in  
{
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = {
    tplink-exporter-living-room = {
      image = "thelastguardian/tplinkexporter";
      networks =  [ "host" ];
      ports = [ "127.0.0.1:9266:9266" ];
      cmd = [
        "--host=${tplink_living_room_ip} --user=admin --password=${tplink_living_room_password}"
      ];
    };

    tplink-exporter-office = {
      image = "thelastguardian/tplinkexporter";
      autoStart = true;
      networks =  [ "host" ];
      ports = [ "127.0.0.1:9267:9266" ];
      volumes = [
        "${config.sops.secrets.tplink_office_ip.path}:/run/secrets/host:ro"
        "${config.sops.secrets.tplink_office_password.path}:/run/secrets/password:ro"
      ];
      cmd = [
        "--host=${tplink_office_ip} --user=admin --password=${tplink_office_password}"
      ];
    };

    nextdns-exporter = {
      image = "ghcr.io/raylas/nextdns-exporter"; 
      autoStart = true;
      networks =  [ "host" ];
      ports = [ "127.0.0.1:9948:9948" ];
      environmentFiles = [ config.sops.secrets.containers_env.path ];
    };
  };
}