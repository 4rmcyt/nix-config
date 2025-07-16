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
        scrape_interval = "2s";  # Real-time updates
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
      tplink.devices = {
        "tplink_living_room" = {
          credentialsFile = config.sops.secrets.tplink_living_room.path;
          port = 9266;
        };
        "tplink_office" = {
          credentialsFile = config.sops.secrets.tplink_office.path;
          port = 9267;
        };
      };
      nextdns = {
        enable = true;
        port = 9790;
        # Corrected to use the new 'profileFile' option
        profileFile = config.sops.secrets.homepage_nextdns_profile_id.path;
        apiKeyFile = config.sops.secrets.nextdns_api_key.path;
      };
    };


    # Rule files for alerting
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

              - alert: HighMemoryUsage
                expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
                for: 5m
                labels:
                  severity: critical
                annotations:
                  summary: "High memory usage detected"

              - alert: DiskSpaceLow
                expr: 100 - ((node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes) > 85
                for: 5m
                labels:
                  severity: warning
                annotations:
                  summary: "Disk space is running low"
      '')
    ];
  };

  # Superior web dashboard
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3000;
        http_addr = "0.0.0.0";
        root_url = "http://192.168.1.165:3000";
        serve_from_sub_path = false;
      };
      security = {
        admin_user = "admin";
        admin_password_file = config.sops.secrets.grafana_admin_password.path;
      };
      "auth.anonymous" = {
        enabled = false;
      };
      analytics = {
        reporting_enabled = false;
      };
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://localhost:9090";
          isDefault = true;
          jsonData = {
            timeInterval = "5s";
            queryTimeout = "60s";
            httpMethod = "POST";
          };
        }
      ];

      # Pre-built dashboard
      dashboards.settings.providers = [
        {
          name = "System Dashboard";
          type = "file";
          options.path = "/var/lib/grafana/dashboards";
        }
      ];
    };
  };

  # Create a basic system dashboard
  systemd.tmpfiles.rules = [
    "d /var/lib/grafana/dashboards 0755 grafana grafana -"
  ];

  # Dashboard JSON file
  environment.etc."grafana-dashboards/system.json".text = builtins.toJSON {
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

  # CLEANED: Only monitoring-specific packages (removed duplicates)
  environment.systemPackages = with pkgs; [
    # Advanced monitoring tools (NOT in configuration.nix)
    iotop         # I/O monitor
    nethogs       # Network per process
    bandwhich     # Network bandwidth
    bmon          # Network monitor
    ncdu          # Disk usage analyzer
    iftop         # Network connections
  ];
}