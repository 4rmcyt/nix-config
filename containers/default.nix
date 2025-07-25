{ config, pkgs, ... }:
{
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = {
    tplink-exporter-living-room = {
      image = "thelastguardian/tplinkexporter";
      autoStart = true;
      networks =  [ "host" ];
      ports = [ "127.0.0.1:9266:9266" ];
      volumes = [
        "${config.sops.secrets.tplink_living_room_ip.path}:/run/secrets/host:ro"
        "${config.sops.secrets.tplink_living_room_password.path}:/run/secrets/password:ro"
      ];
      # 1. Override the entrypoint to be a shell
      entrypoint = [ "/bin/sh" "-c" ];
      # 2. The cmd now becomes the script for the shell to execute
      cmd = [
        "exec /usr/local/bin/tplinkexporter --host=$(cat /run/secrets/host) --user=admin --password=$(cat /run/secrets/password)"
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
      # 1. Override the entrypoint to be a shell
      entrypoint = [ "/bin/sh" "-c" ];
      # 2. The cmd now becomes the script for the shell to execute
      cmd = [
        "exec /usr/local/bin/tplinkexporter --host=$(cat /run/secrets/host) --user=admin --password=$(cat /run/secrets/password)"
      ];
    };

    nextdns-exporter = {
      image = "ghcr.io/raylas/nextdns-exporter";
      autoStart = true;
      networks =  [ "host" ];
      ports = [ "127.0.0.1:9948:9948" ];
      # This is the correct and preferred method when an app supports it
      environmentFiles = [ config.sops.secrets.containers_env.path ];
    };
  };
}

