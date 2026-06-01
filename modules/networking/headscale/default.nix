{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.my.headscale;
  inherit (config.my.defaults) domain;
in {
  options.my.headscale = {
    enable = mkEnableOption "Headscale coordination server";

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port headscale listens on (127.0.0.1 only).";
    };

    subdomain = mkOption {
      type = types.str;
      default = "hs";
      description = "Subdomain prefix for server_url (e.g. 'hs' → https://hs.domain).";
    };

    metricsPort = mkOption {
      type = types.port;
      default = 9091;
      description = "Port for Prometheus metrics endpoint (127.0.0.1 only).";
    };

    dns = {
      nameservers = mkOption {
        type = types.listOf types.str;
        default = ["45.90.28.163" "45.90.30.163"];
        description = "Global nameservers pushed to Tailnet nodes (e.g. NextDNS).";
      };
      splitNameservers = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Nameservers used for split DNS domains. Defaults to nameservers if empty.";
      };
      splitDomains = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Domains to resolve via splitNameservers.";
      };
    };

    derp = {
      regionId = mkOption {
        type = types.int;
        default = 901;
        description = "DERP region ID (must be unique across all regions).";
      };
      regionCode = mkOption {
        type = types.str;
        default = "relay";
        description = "Short DERP region code.";
      };
      regionName = mkOption {
        type = types.str;
        default = "Relay";
        description = "Human-readable DERP region name.";
      };
    };
  };

  config = mkIf cfg.enable {
    services.headscale = {
      enable = true;
      address = "127.0.0.1";
      inherit (cfg) port;

      settings = {
        server_url = "https://${cfg.subdomain}.${domain}";
        noise.private_key_path = "/var/lib/headscale/noise_private.key";

        log = {
          level = "info";
          format = "text";
        };
        logtail.enabled = false;

        database = {
          type = "sqlite";
          sqlite.path = "/var/lib/headscale/db.sqlite";
        };

        dns = {
          magic_dns = true;
          base_domain = "ts.${domain}";
          nameservers.global = cfg.dns.nameservers;
          nameservers.split = listToAttrs (map (d: {
              name = d;
              value = if cfg.dns.splitNameservers != [] then cfg.dns.splitNameservers else cfg.dns.nameservers;
            })
            cfg.dns.splitDomains);
          search_domains = [];
        };

        derp = {
          server = {
            enabled = true;
            region_id = cfg.derp.regionId;
            region_code = cfg.derp.regionCode;
            region_name = cfg.derp.regionName;
            stun_listen_addr = "0.0.0.0:3478";
          };
          auto_update_enabled = true;
          urls = ["https://controlplane.tailscale.com/derpmap/default"];
        };

        metrics_listen_addr = "127.0.0.1:${toString cfg.metricsPort}";
      };
    };

    networking.firewall.allowedUDPPorts = [3478];
  };
}
