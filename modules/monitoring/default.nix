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
    nextdns_api_key = {
      sopsFile = ../../secrets/nextdns.yaml;
      key = "nextdns_api_key";
      owner = config.users.users.prometheus.name;
      group = config.users.groups.prometheus.name;
      mode = "0400";
    };
    grafana_db_password = {
      sopsFile = ../../secrets/postgresql.yaml;
      key = "grafana_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
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
  };

  users.groups = {
    grafana = { };
    uptime-kuma = { };
    prometheus = { };
  };

  networking.firewall.allowedTCPPorts = [
    3000 # Grafana
    9090 # Prometheus
    9100 # Node Exporter
    9948 # NextDNS Exporter
    3001 # Uptime Kuma
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
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:9090";
          proxyWebsockets = true;
        };
      };
      "uptime-kuma.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:3001";
          proxyWebsockets = true;
        };
      };
      "grafana.labhome.work" = {
        forceSSL = true;
        enableACME = true;
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
      # {
      #   job_name = "cloudflare-exporter";
      #   static_configs = [{
      #     targets = [ "localhost:27196" ];
      #     labels = { instance = "homeserver"; };
      #   }];
      # }

    ];

    exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "systemd"
          "processes"
          "interrupts"
          "cpu"
          "diskstats"
          "meminfo"
          "netdev"
          "netstat"
          "btrfs"
          "stat"
          "time"
          "thermal_zone"
          "hwmon"
        ];
        port = 9100;
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
  # dataDir is managed by the module, no need to set it to default
  settings = {
    server = {
      http_port = 3000;
      # Bind to localhost since it's behind a proxy
      http_addr = "127.0.0.1";
      # This MUST match the public URL from Nginx
      root_url = "https://grafana.labhome.work/grafana";
      serve_from_sub_path = true;
    };
    database = {
      type = "postgres";
      host = "/run/postgresql";
      user = "grafana";
      # Note: Consider using a separate DB password (see recommendations)
      password = config.sops.secrets.grafana_db_password.path;
    };
    security = {
      admin_user = "admin";
      admin_password_file = config.sops.secrets.grafana_admin_password.path;
    };
  };

    provision.enable = true;
    provision.datasources.settings.datasources = [
      {
        name = "Prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://localhost:9090";
        isDefault = true;
      }
    ];

    provision.dashboards.settings.providers = [
      {
        name = "System Dashboard";
        type = "file";
        options.path = "/etc/grafana/dashboards/system.json";
        options.foldersFromFilesStructure = true;
      }
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

  systemd.tmpfiles.rules = [
    "d /var/lib/grafana 0755 grafana grafana -"
    "d /var/lib/grafana/dashboards 0755 grafana grafana -"
  ];
}
