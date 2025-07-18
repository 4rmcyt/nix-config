{ config, pkgs, lib, ... }:

{
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
    # The adminPasswordFile option has been moved to the correct location below.
    settings = {
      server = {
        http_port = 3000;
        http_addr = "0.0.0.0";
        root_url = "http://192.168.1.165:3000";
      };
      security = {
        admin_user = "admin";
        # This is the correct option for setting the admin password from a file.
        admin_password_file = config.sops.secrets.grafana_secrets.path;
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

    # This is a cleaner way to provision dashboards.
    # The Grafana module handles creating the necessary files and directories.
    provision.dashboards.settings.providers = [
      {
        name = "System Dashboard";
        type = "file";
        options.path = "/var/lib/grafana/dashboards/system.json";
        options.foldersFromFilesStructure = true;
      }
    ];
  };

  # This replaces the systemd.tmpfiles and environment.etc entries for Grafana.
  environment.etc."grafana/dashboards/system.json".text = builtins.toJSON {
    dashboard = {
      id = null;
      title = "HomeServer System Monitoring";
      refresh = "5s";
      time = { from = "now-1h"; to = "now"; };
      panels = [
        {
          id = 1;
          title = "CPU Usage";
          type = "stat";
          targets = [{
            expr = "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)";
            legendFormat = "CPU %";
          }];
          gridPos = { h = 8; w = 6; x = 0; y = 0; };
        }
        {
          id = 2;
          title = "Memory Usage";
          type = "stat";
          targets = [{
            expr = "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100";
            legendFormat = "Memory %";
          }];
          gridPos = { h = 8; w = 6; x = 6; y = 0; };
        }
        {
          id = 3;
          title = "Disk Usage";
          type = "stat";
          targets = [{
            expr = "100 - ((node_filesystem_avail_bytes{mountpoint=\"/\"} * 100) / node_filesystem_size_bytes{mountpoint=\"/\"})";
            legendFormat = "Root %";
          }];
          gridPos = { h = 8; w = 6; x = 12; y = 0; };
        }
        {
          id = 4;
          title = "Network Traffic";
          type = "graph";
          targets = [
            {
              expr = "rate(node_network_receive_bytes_total{device!=\"lo\"}[5m])";
              legendFormat = "RX {{device}}";
            }
            {
              expr = "rate(node_network_transmit_bytes_total{device!=\"lo\"}[5m])";
              legendFormat = "TX {{device}}";
            }
          ];
          gridPos = { h = 8; w = 18; x = 0; y = 8; };
        }
      ];
    };
  };
}
