{
  config,
  pkgs,
  lib,
  ...
}:

{

  sops.secrets = {
    grafana_admin_password = {
      sopsFile = ../../secrets/grafana.yaml;
      key = "grafana_admin_password";
      owner = config.users.users.grafana.name;
      group = config.users.groups.grafana.name;
      mode = "0400";
    };
    grafana_db_password = {
      sopsFile = ../../secrets/postgresql.yaml;
      key = "grafana_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
    cloudflare_prometheus_exporter_token = {
      sopsFile = ../../secrets/cloudflare-prometheus-exporter.yaml;
      key = "cloudflare_prometheus_exporter_token";
      owner = config.users.users.cloudflare-prometheus-exporter.name;
      group = config.users.groups.cloudflare-prometheus-exporter.name;
      mode = "0400";
    };
  };

  users.users = {
    grafana = {
      isSystemUser = true;
      group = "grafana";
      extraGroups = [ "users" ];
    };
    uptime-kuma = {
      isSystemUser = true;
      group = "uptime-kuma";
      extraGroups = [
        "users"
        "podman"
      ];
    };
    prometheus = {
      isSystemUser = true;
      group = "prometheus";
      extraGroups = [ "users" ];
    };
    cloudflare-exporter = {
      isSystemUser = true;
      group = "cloudflare-exporter";
      extraGroups = [ "users" ];
    };
  };

  users.groups = {
    grafana = { };
    uptime-kuma = { };
    prometheus = { };
    cloudflare-exporter = { };
  };

  networking.firewall.allowedTCPPorts = [
    3000 # Grafana
    9090 # Prometheus
    9100 # Node Exporter
    9948 # NextDNS Exporter
    9187 # PostgreSQL Exporter
    3001 # Uptime Kuma
    27196 # Cloudflare Exporter
  ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      "prometheus.labhome.work" = {
        forceSSL = true;
        sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
        sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
        locations."/" = {
          proxyPass = "http://localhost:9090";
          proxyWebsockets = true;
        };
      };
      "uptime-kuma.labhome.work" = {
        forceSSL = true;
        sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
        sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
        locations."/" = {
          proxyPass = "http://localhost:3001";
          proxyWebsockets = true;
        };
      };
      "grafana.labhome.work" = {
        forceSSL = true;
        sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
        sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
        locations."/grafana/" = {
          # FIX: Added trailing slash to correctly handle the subpath
          proxyPass = "http://localhost:3000/";
          proxyWebsockets = true;
        };
      };
    };
  };

  services.prometheus = {
    enable = true;
    port = 9090;
    globalConfig = {
      scrape_interval = "5s";
      evaluation_interval = "5s";
    };

    scrapeConfigs = [
      {
        job_name = "node-exporter";
        static_configs = [
          {
            targets = [ "localhost:9100" ];
            labels = {
              instance = "homeserver";
            };
          }
        ];
        scrape_interval = "2s";
      }
      {
        job_name = "prometheus";
        static_configs = [
          {
            targets = [ "localhost:9090" ];
            labels = {
              instance = "homeserver";
            };
          }
        ];
      }
      {
        job_name = "nextdns-exporter";
        static_configs = [
          {
            targets = [ "localhost:9948" ];
            labels = {
              instance = "homeserver";
            };
          }
        ];
      }
      {
        job_name = "postgres-exporter";
        static_configs = [
          {
            targets = [ "localhost:9187" ];
            labels = {
              instance = "homeserver";
            };
          }
        ];
      }
      {
        job_name = "cloudflare-exporter";
        static_configs = [{
          targets = [ "localhost:27196" ];
          labels = { instance = "homeserver"; };
        }];
      }

    ];

    exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "smartctl"
          "cpu"
          "diskstats"
          "meminfo"
          "btrfs"
          "stat"
          "time"
          "thermal_zone"
          "hwmon"
        ];
        port = 9100;
      };

      postgres = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9187;
      };

      # cloudflare = {
      #   enable = true;
      #   port = 27196;
      #   extraFlags = [
      #     "--cloudflare.api-token=${config.sops.secrets.cloudflare_prometheus_exporter_token.path}"
      #     "--cloudflare.zone-id=${config.sops.secrets.cloudflare_zone_id.path}"
      #   ];
      # };
    };

    ruleFiles = [
      (pkgs.writeText "homeserver-alerts.yml" ''
        groups:
          - name: homeserver
            rules:
              - alert: HighCPUUsage
                expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
                for: 5m
                labels:
                  severity: warning
                annotations:
                  summary: "High CPU usage detected"
      '')
    ];
  };

  services.grafana = {
    enable = true;
    dataDir = "/var/lib/grafana";
    settings = {
      server = {
        http_port = 3000;
        http_addr = "0.0.0.0";
        root_url = "http://127.0.0.1:3000";
      };
      database = {
        type = "postgres";
        host = "/run/postgresql";
        user = "grafana";
        passwordFile = config.sops.secrets.grafana_db_password.path;
      };
      security = {
        admin_user = "admin";
        admin_password_file = config.sops.secrets.grafana_admin_password.path;
      };
    };

    provision.dashboards.settings.providers = [
      {
        name = "Custom Dashboards";
        type = "file";
        options.path = ./.;
        options.foldersFromFilesStructure = true;
      }
    ];
  };

  services.uptime-kuma = {
    enable = true;
    settings = {
      port = "3001";
      bind_address = "127.0.0.1";
    };
  };

  services.cloudflare-exporter = {
    enable = true;
    tokenFile = config.sops.secrets.cloudflare_prometheus_exporter_token.path;
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/grafana 0755 grafana grafana -"
    "d /var/lib/grafana/dashboards 0755 grafana grafana -"
  ];
}
