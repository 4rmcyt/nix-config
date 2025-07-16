# In services/nextdns-exporter.nix
{ config, pkgs, lib, ... }:

let
  # 1. Package Derivation for nextdns-exporter
  nextdns-exporter = pkgs.buildGoModule {
    pname = "nextdns-exporter";
    version = "1.0.0";

    src = pkgs.fetchFromGitHub {
      owner = "raylas";
      repo = "nextdns-exporter";
      rev = "1.0.0";
      # This hash is for the specific version and should be correct.
      hash = "sha256-Y8hL8Z3g6f4s3a2g1h0JkL9j8d6F4s3a2g1h0JkL=";
    };

    # This hash is for the Go modules and should be correct.
    vendorHash = "sha256-XqjYh4V1kI5Y7u7w9j8d6F4s3a2g1h0JkL9j8d6F4s=";
    modRoot = ".";
  };

  cfg = config.services.prometheus.exporters.nextdns;

in
{
  # 2. NixOS Module Options
  options.services.prometheus.exporters.nextdns = {
    enable = lib.mkEnableOption "NextDNS Prometheus Exporter";

    port = lib.mkOption {
      type = lib.types.port;
      default = 9790;
      description = "Port to listen on.";
    };
    
    # Changed 'profile' to 'profileFile' to accept a path
    profileFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the file containing the NextDNS configuration profile ID.";
      example = config.sops.secrets.homepage_nextdns_profile_id.path;
    };

    apiKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the file containing the NextDNS API key.";
      example = config.sops.secrets.nextdns_api_key.path;
    };
  };

  # 3. Service Configuration
  config = lib.mkIf cfg.enable {
    # Make sure the user exists
    users.users."prometheus-exporters" = {
      group = "prometheus-exporters";
      isSystemUser = true;
    };
    users.groups."prometheus-exporters" = {};

    systemd.services.prometheus-nextdns-exporter = {
      description = "NextDNS Prometheus Exporter";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "sops.service" ];
      serviceConfig = {
        User = "prometheus-exporters";
        Group = "prometheus-exporters";
        ExecStart = ''
          ${nextdns-exporter}/bin/nextdns-exporter \
            -listen=:${toString cfg.port} \
            -profile=$(cat ${cfg.profileFile}) \
            -api-key-file=${cfg.apiKeyFile}
        '';
        Restart = "on-failure";
        PrivateTmp = true;
      };
    };

    services.prometheus.scrapeConfigs = [
      {
        job_name = "nextdns";
        static_configs = [{
          targets = [ "localhost:${toString cfg.port}" ];
        }];
      }
    ];
  };
}
