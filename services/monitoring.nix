{ config, pkgs, lib, ... }:

{
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
        domain = "localhost";
        root_url = "http://localhost:3000/";
      };
      security = {
        admin_user = "admin";
        admin_password = "$${GRAFANA_ADMIN_PASSWORD}";
      };
      auth.anonymous = {
        enabled = false;
      };
      analytics.reporting_enabled = false;
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

  # REMOVED: Conflicting Caddy extraConfig section
  # The Grafana route is now included directly in caddy.nix

  # Expose prometheus ports in firewall
  networking.firewall.allowedTCPPorts = [
    9090  # Prometheus
    9100  # Node exporter
    3000  # Grafana
  ];
}