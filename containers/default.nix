{ config, pkgs, ... }:
let
  # Read the content of the secret files
  tplink_office_ip = builtins.readFile config.sops.secrets.tplink_office_ip.path;
  tplink_living_room_ip = builtins.readFile config.sops.secrets.tplink_living_room_ip.path;
  tplink_office_password = builtins.readFile config.sops.secrets.tplink_office_password.path;
  tplink_living_room_password = builtins.readFile config.sops.secrets.tplink_living_room_password.path;

  # Generate the config.yml for the new exporter using the secrets
  tplinkExporterConfig = pkgs.writeTextFile {
    name = "tl-sg-exporter-config.yml";
    text = ''
      # Exporter listen address and port
      listen: 0.0.0.0:9266

      # List of switches to scrape
      switches:
        - name: living_room
          host: ${tplink_living_room_ip}
          user: admin
          pass: ${tplink_living_room_password}
        - name: office
          host: ${tplink_office_ip}
          user: admin
          pass: ${tplink_office_password}
    '';
  };
in
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