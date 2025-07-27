{ config, pkgs, lib, ... }:

{
  services.cloudflare-prometheus-exporter = {
    enable = true;
    tokenFile = config.sops.secrets.cloudflare_prometheus_exporter_token.path;
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
        static_configs = [{
          targets = [ "localhost:9100" ];
          labels = { instance = "homeserver"; };
        }];
        scrape_interval = "2s";
      }
      {
        job_name = "prometheus";
        static_configs = [{
          targets = [ "localhost:9090" ];
          labels = { instance = "homeserver"; };
        }];
      }
      {
        job_name = "nextdns-exporter";
        static_configs = [{
          targets = [ "localhost:9948" ];
          labels = { instance = "homeserver"; };
        }];
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
          "systemd" "processes" "interrupts" "cpu" "diskstats"
          "filesystem" "loadavg" "meminfo" "netdev" "netstat"
          "stat" "time" "vmstat" "logind" "thermal_zone"
          "hwmon"
        ];
        port = 9100;
      };
      
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
        options.path = ./.; # This points to the directory
        options.foldersFromFilesStructure = true;
      }
    ];
  };
}
