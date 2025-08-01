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
      owner = "grafana";
      group = "grafana";
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
      extraGroups = [ "users" "podman" ];
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

  services.nginx.virtualHosts."grafana.example.com" = {
    forceSSL = true;
    enableACME = true;
    http2 = true;
    locations."/" = {
      proxyPass = "http://localhost:3000";
      proxyWebsockets = true;
      proxyHeaders = {
        "X-Forwarded-For" = "$proxy_add_x_forwarded_for";
        "X-Forwarded-Proto" = "https";
      };
    };
  };

  services.nginx.virtualHosts."prometheus.example.com" = {
    forceSSL = true;
    enableACME = true;
    http2 = true;
    locations."/" = {
      proxyPass = "http://localhost:9090";
      proxyWebsockets = true;
      proxyHeaders = {
        "X-Forwarded-For" = "$proxy_add_x_forwarded_for";
        "X-Forwarded-Proto" = "https";
      };
    };
  };

  services.nginx.virtualHosts."uptime-kuma.example.com" = {
    forceSSL = true;
    enableACME = true;
    http2 = true;
    locations."/" = {
      proxyPass = "http://localhost:3001";
      proxyWebsockets = true;
      proxyHeaders = {
        "X-Forwarded-For" = "$proxy_add_x_forwarded_for";
        "X-Forwarded-Proto" = "https";
      };
    };
  };

  environment.systemPackages = [
    pkgs.grafana
    pkgs.prometheus
    pkgs.prometheus-cloudflare-exporter
    pkgs.prometheus-node-exporter
  ];

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
    dataDir = "/var/lib/grafana";
    settings = {
      server = {
        http_port = 3000;
        http_addr = "0.0.0.0";
        root_url = "http://192.168.1.165:3000";
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


