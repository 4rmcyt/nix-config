
{ config, pkgs, lib, ... }:

{
  # SOPS secret for Grafana
  sops.secrets.grafana_admin_password = {
    owner = "grafana";
    group = "grafana";
    mode = "0400";
  };

  # Netdata real-time monitoring - Fixed Host header validation
  services.netdata = {
    enable = true;
    config = {
      global = {
        "default port" = "19999";
        "bind to" = "*";
        "access log" = "none";
        "error log" = "syslog";
        "debug log" = "none";
        "update every" = "3";
        "memory mode" = "ram";
        "history" = "3600";
        "hostname" = "homeserver";
      };
      web = {
        "web files owner" = "root";
        "web files group" = "netdata";
        "bind to" = "*";
        "allow connections from" = "localhost 192.168.* *";
        "allow dashboard from" = "localhost 192.168.* *";
        "allow badges from" = "*";
        "allow streaming from" = "*";
        "allow netdata.conf from" = "localhost 192.168.* *";
        "allow management from" = "localhost 192.168.* *";
        "enable gzip compression" = "yes";
        "accept a streaming request every seconds" = "0";
        # Fix Host header validation
        "allow hostnames" = "localhost homeserver 192.168.1.165 *";
        "disconnect idle clients after seconds" = "60";
        "timeout for first request" = "60";
        "timeout for idle connections" = "60";
      };
      # Disable problematic plugins
      "plugin:freeipmi" = {
        "enabled" = "no";
      };
      "plugin:charts.d" = {
        "enabled" = "no";
      };
      "plugin:python.d" = {
        "enabled" = "no";
      };
      "plugin:go.d" = {
        "enabled" = "yes";
      };
      # Disable specific problematic collectors
      "go.d:prometheus:caddy_local" = {
        "enabled" = "no";
      };
      "go.d:prometheus:grafana_local" = {
        "enabled" = "no";
      };
      "go.d:docker" = {
        "enabled" = "no";
      };
      # Disable more problematic plugins
      "plugin:logs-management" = {
        "enabled" = "no";
      };
      "plugin:ioping" = {
        "enabled" = "no";
      };
      "plugin:perf" = {
        "enabled" = "no";
      };
    };
  };

  # Prometheus monitoring server
  services.prometheus = {
    enable = true;
    port = 9090;

    # Basic scrape configs to monitor the system and services
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [ "localhost:9100" ];
          labels = {
            instance = "homeserver";
          };
        }];
      }
      {
        job_name = "caddy";
        static_configs = [{
          targets = [ "localhost:2019" ];
          labels = {
            instance = "homeserver";
          };
        }];
      }
      {
        job_name = "prometheus";
        static_configs = [{
          targets = [ "localhost:9090" ];
          labels = {
            instance = "homeserver";
          };
        }];
      }
      {
        job_name = "netdata";
        static_configs = [{
          targets = [ "localhost:19999" ];
          labels = {
            instance = "homeserver";
          };
        }];
        metrics_path = "/api/v1/allmetrics";
        params = {
          format = ["prometheus"];
        };
      }
    ];

    # Add exporters for system metrics
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9100;
      };
    };
  };

  # Grafana for visualization - Fixed SOPS secret configuration
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3000;
        http_addr = "0.0.0.0";  # Listen on all interfaces
      };
      security = {
        admin_user = "admin";
        # Use admin_password_file instead of admin_password for SOPS secrets
        admin_password_file = config.sops.secrets.grafana_admin_password.path;
      };
      "auth.anonymous" = {
        enabled = false;
      };
      analytics = {
        reporting_enabled = false;
      };
      metrics = {
        enabled = true;
        basic_auth_username = "";
        basic_auth_password = "";
      };
    };

    # Provision datasources automatically
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://localhost:9090";
          isDefault = true;
        }
      ];
    };
  };

  # Expose prometheus ports in firewall
  networking.firewall.allowedTCPPorts = [
    9090  # Prometheus
    9100  # Node exporter
    3000  # Grafana
    19999 # Netdata
  ];
}