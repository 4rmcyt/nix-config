
{ config, pkgs, lib, ... }:

{
  # SOPS secret for Grafana
  sops.secrets.grafana_admin_password = {
    owner = "grafana";
    group = "grafana";
    mode = "0400";
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

  # Grafana for visualization
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3000;
        domain = "192.168.1.165";  # Changed from localhost
        root_url = "http://192.168.1.165/grafana/";  # Changed to use server IP
        serve_from_sub_path = true;
      };
      security = {
        admin_user = "admin";
        admin_password = "$__file{${config.sops.secrets.grafana_admin_password.path}}";
      };
      "auth.anonymous" = {
        enabled = false;
      };
      analytics = {
        reporting_enabled = false;
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
  ];
}