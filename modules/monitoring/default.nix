{
  config,
  pkgs,
  ...
}: {
  # =================================================================
  # 1. SOPS Secrets
  # =================================================================
  sops.secrets = {
    cloudflare_prometheus_exporter_token = {
      sopsFile = ../../secrets/cloudflare-prometheus-exporter.yaml;
      key = "cloudflare_prometheus_exporter_token";
    };
    grafana_admin_password = {
      sopsFile = ../../secrets/grafana.yaml;
      owner = config.users.users.grafana.name;
    };
    grafana_db_password = {
      sopsFile = ../../secrets/postgresql.yaml;
      owner = config.users.users.postgresql.name;
    };
    grafana_oauth_secret = {
      sopsFile = ../../secrets/authentik.yaml;
      key = "grafana_oauth_secret";
      owner = config.users.users.grafana.name;
      mode = "0400";
    };
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
    nut-exporter = {
      isSystemUser = true;
      description = "NUT Exporter user";
      group = "nut-exporter";
    };
    prometheus = {
      isSystemUser = true;
      description = "Prometheus daemon user";
      group = "prometheus";
    };
    uptime-kuma = {
      isSystemUser = true;
      description = "Uptime Kuma user";
      group = "uptime-kuma";
    };
  };

  users.groups = {
    grafana = {};
    nut-exporter = {};
    prometheus = {};
    uptime-kuma = {};
  };

  # =================================================================
  # 3. Firewall
  # =================================================================
  networking.firewall.allowedTCPPorts = [
    3000 # Grafana
    3001 # Uptime Kuma
    8081 # Cloudflare Exporter
    9090 # Prometheus
    9100 # Node Exporter
    9187 # PostgreSQL Exporter
    9199 # NUT Exporter
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
        security.admin_password_file = config.sops.secrets.grafana_admin_password.path;
        server = {
          http_addr = "127.0.0.1";
          http_port = 3003;
          root_url = "https://grafana.${config.my.defaults.domain}";
        };
        "auth.generic_oauth" = {
          enabled = true;
          name = "Authentik";
          client_id = "grafana";
          client_secret = "$__file{${config.sops.secrets.grafana_oauth_secret.path}}";
          scopes = "openid profile email";
          auth_url = "https://auth.${config.my.defaults.domain}/application/o/authorize/";
          token_url = "https://auth.${config.my.defaults.domain}/application/o/token/";
          api_url = "https://auth.${config.my.defaults.domain}/application/o/userinfo/";
          role_attribute_path = "contains(groups, 'Grafana Admins') && 'Admin' || contains(groups, 'Grafana Editors') && 'Editor' || 'Viewer'";
          allow_sign_up = true;
        };
      };
      provision.datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://localhost:9090";
          isDefault = true;
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
        postgres = {
          enable = true;
        };
      };

      scrapeConfigs = [
        {
          job_name = "cloudflare-exporter";
          static_configs = [{targets = ["localhost:8081"];}];
        }
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
            {targets = ["localhost:${toString config.my.network.ports.node-exporter}"];}
          ];
        }
        {
          job_name = "postgres-exporter";
          static_configs = [{targets = ["localhost:9187"];}];
        }
        {
          job_name = "prometheus";
          static_configs = [{targets = ["localhost:${toString config.my.network.ports.prometheus}"];}];
        }
      ];
    };

    # --- Uptime Kuma ---
    uptime-kuma = {
      enable = true;
      settings = {
        hostname = "127.0.0.1";
        port = "3001";
      };
    };
  };

  # =================================================================
  # 5. Custom Systemd Services for Exporters
  # =================================================================
  systemd.services.cloudflare-exporter = {
    description = "Cloudflare Prometheus Exporter";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    serviceConfig = {
      User = "prometheus";
      Group = "prometheus";
      EnvironmentFile = config.sops.secrets.cloudflare_prometheus_exporter_token.path;
      ExecStart = ''
        ${pkgs.prometheus-cloudflare-exporter}/bin/cloudflare-exporter \
          --listen "127.0.0.1:8081" \
          --cf_api_token "$CLOUDFLARE_PROMETHEUS_EXPORTER_TOKEN"
      '';
      Restart = "always";
      RestartSec = 10;
    };
  };
}
