{config, ...}: {
  # =================================================================
  # 1. SOPS Secrets
  # =================================================================
  # Env file for Tailscale exporter — rendered at activation, before any service starts
  # Uses "-" as tailnet (Tailscale API convention for "current user's tailnet")

  sops.secrets = {
    grafana_admin_password = {
      sopsFile = ../../secrets/grafana.yaml;
      key = "grafana_admin_password";
      owner = config.users.users.grafana.name;
    };
    grafana_db_password = {
      sopsFile = ../../secrets/postgresql.yaml;
      owner = config.users.users.postgres.name;
    };
    grafana_oidc_client_secret = {
      sopsFile = ../../secrets/grafana.yaml;
      key = "grafana_oidc_client_secret";
      owner = config.users.users.grafana.name;
    };
    grafana_secret_key = {
      sopsFile = ../../secrets/grafana.yaml;
      key = "grafana_secret_key";
      owner = config.users.users.grafana.name;
    };
    # tailscale_prometheus_exporter_env = {
    #   sopsFile = ../../secrets/tailscale-prometheus-exporter.env;
    #   format = "dotenv";
    # };
  };

  # =================================================================
  # 2. Users and Groups
  # =================================================================
  users.users = {
    grafana = {
      isSystemUser = true;
      description = "Grafana user";
      group = "grafana";
    };
    prometheus = {
      isSystemUser = true;
      description = "Prometheus daemon user";
      group = "prometheus";
    };
  };

  users.groups = {
    grafana = {};
    prometheus = {};
  };

  # =================================================================
  # 3. Firewall
  # =================================================================
  networking.firewall.allowedTCPPorts = [
    3003 # Grafana
    9090 # Prometheus
    9100 # Node Exporter
    9199 # NUT Exporter
    # 9250 # Tailscale Exporter
  ];

  # =================================================================
  # 4. Services
  # =================================================================
  services = {
    # --- Grafana Visualization ---
    grafana = {
      enable = true;
      settings = {
        database = {
          type = "postgres";
          host = "/run/postgresql";
          user = "grafana";
          passwordFile = config.sops.secrets.grafana_db_password.path;
        };
        security = {
          admin_password_file = config.sops.secrets.grafana_admin_password.path;
          secret_key = "$__file{${config.sops.secrets.grafana_secret_key.path}}";
        };
        server = {
          http_addr = "127.0.0.1";
          http_port = 3003;
          root_url = "https://grafana.${config.my.defaults.domain}";
        };
        "auth.generic_oauth" = {
          enabled = true;
          name = "Authelia";
          client_id = "grafana";
          client_secret = "$__file{${config.sops.secrets.grafana_oidc_client_secret.path}}";
          scopes = "openid profile email groups";
          auth_url = "https://auth.${config.my.defaults.domain}/api/oidc/authorization";
          token_url = "https://auth.${config.my.defaults.domain}/api/oidc/token";
          api_url = "https://auth.${config.my.defaults.domain}/api/oidc/userinfo";
          role_attribute_path = "contains(groups[*], 'admin') && 'Admin' || 'Viewer'";
          allow_sign_up = true;
        };
      };
      provision.datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://localhost:${toString config.services.prometheus.port}";
          isDefault = true;
        }
      ];
      provision.dashboards.settings.providers = [
        {
          name = "GitHub Actions";
          options.path = ./dashboards;
          disableDeletion = false;
          updateIntervalSeconds = 30;
        }
      ];
    };

    # --- Prometheus Monitoring Stack ---
    prometheus = {
      enable = true;
      port = 9090;
      retentionTime = "30d";
      globalConfig.scrape_interval = "1m";
      ruleFiles = [./alerts/homeserver.yaml];

      exporters = {
        node = {
          enable = true;
          enabledCollectors = [
            "diskstats"
            "meminfo"
            "netdev"
            "pressure"
            "stat"
            "systemd"
            "thermal_zone"
            "time"
            "zfs"
          ];
        };
        nut = {
          enable = true;
          nutServer = "localhost";
          nutUser = "upsmon";
          passwordPath = config.sops.secrets.nut_password.path;
          nutVariables = [
            "battery.charge"
            "battery.runtime"
            "battery.voltage"
            "battery.voltage.nominal"
            "input.voltage"
            "input.voltage.nominal"
            "ups.load"
            "ups.status"
          ];
        };
        # postgres = {
        #   enable = true;
        # };
        # tailscale = {
        #   enable = true;
        #   environmentFile = config.sops.secrets.tailscale_prometheus_exporter_env.path;
        # };
      };

      scrapeConfigs = [
        {
          job_name = "desktop-node";
          static_configs = [
            {
              targets = [
                "${config.my.network.hosts.desktop_lan}:${toString config.my.network.ports.node-exporter}"
              ];
            }
          ];
        }
        {
          job_name = "homeserver-node";
          static_configs = [
            {targets = ["localhost:9100"];}
          ];
        }
        {
          job_name = "nut-exporter";
          static_configs = [
            {targets = ["localhost:9199"];}
          ];
          metrics_path = "/ups_metrics";
        }
        # {
        #   job_name = "postgres-exporter";
        #   static_configs = [
        #     {targets = ["localhost:9187"];}
        #   ];
        # }
        {
          job_name = "prometheus";
          static_configs = [{targets = ["localhost:${toString config.my.network.ports.prometheus}"];}];
        }
        # {
        #   job_name = "tailscale";
        #   static_configs = [{targets = ["localhost:9250"];}];
        # }
      ];
    };
  };
}
