{
  config,
  pkgs,
  ...
}:
{
  # =================================================================
  # 1. SOPS Secrets
  # =================================================================
  sops.secrets = {
    grafana_admin_password = {
      sopsFile = ../../secrets/grafana.yaml;
      owner = config.users.users.grafana.name;
    };
    grafana_db_password = {
      sopsFile = ../../secrets/postgresql.yaml;
      owner = config.users.users.postgresql.name;
    };
    cloudflare_prometheus_exporter_token = {
      sopsFile = ../../secrets/cloudflare-prometheus-exporter.yaml;
      key = "cloudflare_prometheus_exporter_token";
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
    uptime-kuma = {
      isSystemUser = true;
      description = "Uptime Kuma user";
      group = "uptime-kuma";
    };
    prometheus = {
      isSystemUser = true;
      description = "Prometheus daemon user";
      group = "prometheus";
    };
  };
  users.groups = {
    grafana = { };
    uptime-kuma = { };
    prometheus = { };
  };

  # =================================================================
  # 3. Firewall
  # =================================================================
  networking.firewall.allowedTCPPorts = [
    3000 # Grafana
    9090 # Prometheus
    9100 # Node Exporter
    9187 # PostgreSQL Exporter
    3001 # Uptime Kuma
    8081 # Cloudflare Exporter
  ];
  # =================================================================
  # 5. Services
  # =================================================================
  services = {
    # services.nginx = {
    #   enable = true;
    #   recommendedGzipSettings = true;
    #   recommendedOptimisation = true;
    #   recommendedProxySettings = true;
    #   recommendedTlsSettings = true;

    #   virtualHosts = {
    #     "prometheus.example.com" = {
    #       forceSSL = true;
    #       sslCertificate = config.my.security.ssl.certPath;
    #       sslCertificateKey = config.my.security.ssl.keyPath;
    #       locations."/".proxyPass = "http://localhost:9090";
    #     };
    #     "uptime-kuma.example.com" = {
    #       forceSSL = true;
    #       sslCertificate = config.my.security.ssl.certPath;
    #       sslCertificateKey = config.my.security.ssl.keyPath;
    #       locations."/".proxyPass = "http://localhost:3001";
    #     };
    #     "grafana.example.com" = {
    #       forceSSL = true;
    #       sslCertificate = config.my.security.ssl.certPath;
    #       sslCertificateKey = config.my.security.ssl.keyPath;
    #       extraConfig = "add_header Strict-Transport-Security \"max-age=31536000; includeSubDomains\" always;";
    #       locations."/".proxyPass = "http://localhost:3000/";
    #     };
    #   };
    # };

    # --- Prometheus Monitoring Stack ---
    prometheus = {
      enable = true;
      port = 9090;
      retentionTime = "30d";
      globalConfig.scrape_interval = "1m";
      scrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = [ { targets = [ "localhost:9090" ]; } ];
        }
        {
          job_name = "homeserver-node";
          static_configs = [ { targets = [ "localhost:9100" ]; } ];
        }
        {
          job_name = "desktop-node";
          static_configs = [ { targets = [ "desktop:9100" ]; } ];
        }
        {
          job_name = "postgres-exporter";
          static_configs = [ { targets = [ "localhost:9187" ]; } ];
        }
        {
          job_name = "cloudflare-exporter";
          static_configs = [ { targets = [ "localhost:8081" ]; } ];
        }
      ];
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [
            "systemd"
            "zfs"
            "diskstats"
            "meminfo"
            "netdev"
            "stat"
            "time"
            "thermal_zone"
          ];
        };
        postgres = {
          enable = true;
        };
      };
      ruleFiles = [ ./alerts/homeserver.yaml ];
    };

    # --- Grafana Visualization ---
    grafana = {
      enable = true;
      settings = {
        server = {
          http_port = 3000;
          root_url = "http://grafana.example.com";
        };
        database = {
          type = "postgres";
          host = "/run/postgresql";
          user = "grafana";
          passwordFile = config.sops.secrets.grafana_db_password.path;
        };
        security.admin_password_file = config.sops.secrets.grafana_admin_password.path;
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
    # --- Uptime Kuma ---
    uptime-kuma = {
      enable = true;
      settings = {
        port = "3001";
        hostname = "127.0.0.1";
      };
    };
  };
  # =================================================================
  # 6. Custom Systemd Services for Exporters
  # =================================================================
  systemd.services.cloudflare-exporter = {
    description = "Cloudflare Prometheus Exporter";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "prometheus";
      # Corrected ExecStart command
      ExecStart = ''
        ${pkgs.prometheus-cloudflare-exporter}/bin/cloudflare-exporter \
          --listen "127.0.0.1:8081" \
          --cf_api_token zRPFePg3TzQtbZPx9mWca7fyLwQEtEu6yQ9A0tQa
      '';
    };
  };
}
