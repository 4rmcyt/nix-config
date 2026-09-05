{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.my.headscale;
  inherit (config.my.defaults) domain;

  # Fixed: headscale listens on 127.0.0.1:8080, metrics on 127.0.0.1:9091,
  # server_url is https://hs.<domain>. Never varied per host.
  port = 8080;
  metricsPort = 9091;
in {
  options.my.headscale = {
    enable = mkEnableOption "Headscale coordination server";

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
      latitude = mkOption {
        type = types.float;
        default = 0.0;
        description = "DERP server latitude (used by clients for latency-based selection).";
      };
      longitude = mkOption {
        type = types.float;
        default = 0.0;
        description = "DERP server longitude (used by clients for latency-based selection).";
      };
    };
  };

  config = mkIf cfg.enable {
    services.headscale = {
      enable = true;
      address = "127.0.0.1";
      inherit port;

      settings = {
        server_url = "https://hs.${domain}";
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
              value =
                if cfg.dns.splitNameservers != []
                then cfg.dns.splitNameservers
                else cfg.dns.nameservers;
            })
            cfg.dns.splitDomains);
          search_domains = [];
        };

        derp = {
          server = {
            enabled = true;
            region_id = 901;
            region_code = cfg.derp.regionCode;
            region_name = cfg.derp.regionName;
            stun_listen_addr = "0.0.0.0:3478";
            latitude = cfg.derp.latitude;
            longitude = cfg.derp.longitude;
          };
          auto_update_enabled = true;
          urls = ["https://controlplane.tailscale.com/derpmap/default"];
        };

        metrics_listen_addr = "127.0.0.1:${toString metricsPort}";
      };
    };

    networking.firewall.allowedUDPPorts = [3478];
  };
}
