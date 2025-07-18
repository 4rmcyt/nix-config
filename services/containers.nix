# In services/containers.nix
{ config, pkgs, lib, ... }:

{
  # 1. Enable Podman
  virtualisation.podman.enable = true;

  # 2. Define the systemd services that will run the containers
  systemd.services = {
    # --- TP-Link Exporter for Living Room ---
    podman-tplink-exporter-living-room = {
      description = "TP-Link Exporter for Living Room";
      after = [ "network-online.target" "sops.service" ];
      wants = [ "network-online.target" "sops.service" ];
      serviceConfig = {
        Restart = "always";
        ExecStartPre = "${pkgs.podman}/bin/podman pull docker.io/thelastguardian/tplinkexporter:latest";
        # This script now reads all credentials from a single JSON file
        ExecStart = let
          startScript = pkgs.writeShellScript "start-tplink-living-room" ''
            #!${pkgs.bash}/bin/bash
            set -euo pipefail
            
            # Read all credentials from the single JSON file
            CREDS_JSON=$(cat /run/credentials/podman-tplink-exporter-living-room.service/tplink_living_room_creds)
            
            IP=$(echo "$CREDS_JSON" | ${pkgs.jq}/bin/jq -r .ip)
            USER=$(echo "$CREDS_JSON" | ${pkgs.jq}/bin/jq -r .user)
            PASSWORD=$(echo "$CREDS_JSON" | ${pkgs.jq}/bin/jq -r .password)

            # The exporter needs a YAML config file with the device IP.
            # We create it on the fly.
            CONFIG_FILE=$(mktemp)
            trap 'rm -f "$CONFIG_FILE"' EXIT
            
            cat > "$CONFIG_FILE" <<EOF
            devices:
              "$IP": "living-room"
            EOF

            # Run the container, mounting the dynamically created config file
            exec ${pkgs.podman}/bin/podman run --rm --name tplink-exporter-living-room \
              --network=host \
              -e TPLINK_USER="$USER" \
              -e TPLINK_PASSWORD="$PASSWORD" \
              -v "$CONFIG_FILE:/config.yaml" \
              docker.io/thelastguardian/tplinkexporter:latest \
              --web.listen-address=:9266 \
              --config.file=/config.yaml
          '';
        in
          "${startScript}";
        # Load the single JSON secret file for this device
        LoadCredential = [
          "tplink_living_room_creds:${config.sops.secrets.system.tplink_living_room_creds.path}"
        ];
      };
    };

    # --- TP-Link Exporter for Office ---
    podman-tplink-exporter-office = {
      description = "TP-Link Exporter for Office";
      after = [ "network-online.target" "sops.service" ];
      wants = [ "network-online.target" "sops.service" ];
      serviceConfig = {
        Restart = "always";
        ExecStartPre = "${pkgs.podman}/bin/podman pull docker.io/thelastguardian/tplinkexporter:latest";
        ExecStart = let
          startScript = pkgs.writeShellScript "start-tplink-office" ''
            #!${pkgs.bash}/bin/bash
            set -euo pipefail
            
            CREDS_JSON=$(cat /run/credentials/podman-tplink-exporter-office.service/tplink_office_creds)
            
            IP=$(echo "$CREDS_JSON" | ${pkgs.jq}/bin/jq -r .ip)
            USER=$(echo "$CREDS_JSON" | ${pkgs.jq}/bin/jq -r .user)
            PASSWORD=$(echo "$CREDS_JSON" | ${pkgs.jq}/bin/jq -r .password)

            CONFIG_FILE=$(mktemp)
            trap 'rm -f "$CONFIG_FILE"' EXIT
            
            cat > "$CONFIG_FILE" <<EOF
            devices:
              "$IP": "office"
            EOF

            exec ${pkgs.podman}/bin/podman run --rm --name tplink-exporter-office \
              --network=host \
              -e TPLINK_USER="$USER" \
              -e TPLINK_PASSWORD="$PASSWORD" \
              -v "$CONFIG_FILE:/config.yaml" \
              docker.io/thelastguardian/tplinkexporter:latest \
              --web.listen-address=:9267 \
              --config.file=/config.yaml
          '';
        in
          "${startScript}";
        LoadCredential = [
          "tplink_office_creds:${config.sops.secrets.tplink_office_creds.path}"
        ];
      };
    };

    # --- NextDNS Exporter ---
    podman-nextdns-exporter = {
      description = "NextDNS Prometheus Exporter";
      after = [ "network-online.target" "sops.service" ];
      wants = [ "network-online.target" "sops.service" ];
      serviceConfig = {
        Restart = "always";
        ExecStartPre = "${pkgs.podman}/bin/podman pull ghcr.io/raylas/nextdns-exporter:latest";
        ExecStart = ''
          ${pkgs.podman}/bin/podman run --rm --name nextdns-exporter \
            --network=host \
            ghcr.io/raylas/nextdns-exporter:latest \
            -listen=:9790 \
            -profile=$(cat ${config.sops.secrets.nextdns.nextdns_profile_id.path}) \
            -api-key=$(cat ${config.sops.secrets.nextdns.nextdns_api_key.path})
        '';
      };
    };
  };

  # 4. Define Prometheus scrape configs for the new containerized exporters
  services.prometheus.scrapeConfigs = [
    {
      job_name = "tplink-living-room";
      static_configs = [{ targets = [ "localhost:9266" ]; }];
    }
    {
      job_name = "tplink-office";
      static_configs = [{ targets = [ "localhost:9267" ]; }];
    }
    {
      job_name = "nextdns";
      static_configs = [{ targets = [ "localhost:9790" ]; }];
    }
  ];
}
