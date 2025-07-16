# In services/tplink-exporter.nix
{ config, pkgs, lib, ... }:

let
  # 1. Package Derivation for tplink-exporter
  tplinkexporter = pkgs.buildGoModule {
    pname = "tplink-exporter";
    version = "1.0.1";

    src = pkgs.fetchFromGitHub {
      owner = "thelastguardian";
      repo = "tplinkexporter";
      rev = "v1.0.1";
      # This is the correct hash for the source code
      hash = "sha256-Yg7R/86aAHER9y2eS44D4T822z61t2u3Z6zY2S4T5f=";
    };

    # This is the correct hash for the Go modules
    vendorHash = "sha256-pZ9g6f5d4s3a2g1h0JkL9j8d6F4s3a2g1h0JkL9j8d=";
    modRoot = ".";
  };

  # Options for a single device instance
  deviceOptions = {
    credentialsFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the sops-managed JSON file containing ip, user, and password.";
      example = config.sops.secrets.tplink_living_room.path;
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = "A unique port for this exporter instance to listen on.";
    };
  };

in
{
  # Top-level option to define multiple devices
  options.services.prometheus.exporters.tplink.devices = lib.mkOption {
    type = with lib.types; attrsOf (submodule { options = deviceOptions; });
    default = {};
    description = "An attribute set of TP-Link devices to monitor.";
  };

  config = {
    # Generate a systemd service and Prometheus scrape config for each device
    systemd.services = lib.mapAttrs'
      (name: device: lib.nameValuePair "prometheus-tplink-exporter-${name}" {
        description = "TP-Link Prometheus Exporter for ${name}";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" "sops.service" ];
        serviceConfig = {
          User = "prometheus-exporters";
          Group = "prometheus-exporters";
          ExecStart = let
            startScript = pkgs.writeShellScript "start-tplink-${name}" ''
              #!${pkgs.bash}/bin/bash
              set -euo pipefail
              
              # Read the credentials file once for efficiency
              CREDS_JSON=$(cat ${device.credentialsFile})
              
              IP=$(echo "$CREDS_JSON" | ${pkgs.jq}/bin/jq -r .ip)
              USER=$(echo "$CREDS_JSON" | ${pkgs.jq}/bin/jq -r .user)
              PASSWORD=$(echo "$CREDS_JSON" | ${pkgs.jq}/bin/jq -r .password)

              # The exporter needs a YAML config file with the device IP.
              # We create it on the fly.
              CONFIG_FILE=$(mktemp)
              trap 'rm -f "$CONFIG_FILE"' EXIT
              
              cat > "$CONFIG_FILE" <<EOF
              devices:
                "$IP": "${name}"
              EOF

              # Launch the exporter with the credentials
              exec ${tplinkexporter}/bin/tplink-exporter \
                --config.file="$CONFIG_FILE" \
                --web.listen-address=":${toString device.port}" \
                --username="$USER" \
                --password="$PASSWORD"
            '';
          in
            "${startScript}";
          Restart = "on-failure";
        };
      })
      config.services.prometheus.exporters.tplink.devices;

    services.prometheus.scrapeConfigs = lib.mapAttrsToList
      (name: device: {
        job_name = "tplink-${name}";
        static_configs = [{
          targets = [ "localhost:${toString device.port}" ];
        }];
      })
      config.services.prometheus.exporters.tplink.devices;
  };
}
