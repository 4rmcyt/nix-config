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
      # Add more exporters as needed
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
        # Use SOPS for password in production
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

  # Update Caddy configuration to expose Grafana
  services.caddy.extraConfig = lib.mkIf config.services.caddy.enable (lib.mkAfter ''
    # Grafana
    handle_path /grafana* {
      reverse_proxy localhost:3000 {
        header_up Host {upstream_hostport}
        header_up X-Real-IP {remote_host}
      }
    }
  '');

  # Alerting configuration (commented as reference)
  # services.prometheus.alertmanager = {
  #   enable = true;
  #   port = 9093;
  #   configuration = {
  #     route = {
  #       group_by = [ "alertname" ];
  #       group_wait = "30s";
  #       group_interval = "5m";
  #       repeat_interval = "4h";
  #       receiver = "telegram";
  #     };
  #     receivers = [
  #       {
  #         name = "telegram";
  #         telegram_configs = [
  #           {
  #             bot_token = "$${TELEGRAM_BOT_TOKEN}";
  #             chat_id = 123456789;
  #             parse_mode = "HTML";
  #           }
  #         ];
  #       }
  #     ];
  #   };
  # };

  # Expose prometheus ports in firewall
  networking.firewall.allowedTCPPorts = [
    9090  # Prometheus
    9100  # Node exporter
    3000  # Grafana
  ];
}
