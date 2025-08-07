{
  config,
  pkgs,
  lib,
  ...
}:

{
  # =================================================================
  # 1. SOPS Secrets
  # This section looks good.
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
    };
  };

  # =================================================================
  # 2. Users and Groups
  # Defining service users here is fine.
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
    loki = {
      isSystemUser = true;
      description = "Loki Service User";
      group = "loki";
    };
    promtail = {
      isSystemUser = true;
      description = "Promtail service user";
      group = "promtail";
    };
  };
  users.groups = {
    grafana = { };
    uptime-kuma = { };
    prometheus = { };
    loki = { };
    promtail = { };
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
    3100 # Loki
  ];

  # =================================================================
  # 4. Environment Packages
  # =================================================================
  # NOTE: This block is now empty. Enabling NixOS services automatically
  # adds the necessary packages to the system's PATH. Manually adding
  # them here is redundant.
  environment.systemPackages = [ ];

  # =================================================================
  # 5. Services
  # =================================================================
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      "prometheus.labhome.work" = {
        forceSSL = true;
        sslCertificate = config.my.security.ssl.certPath;
        sslCertificateKey = config.my.security.ssl.keyPath;
        locations."/".proxyPass = "http://localhost:9090";
      };
      "uptime-kuma.labhome.work" = {
        forceSSL = true;
        sslCertificate = config.my.security.ssl.certPath;
        sslCertificateKey = config.my.security.ssl.keyPath;
        locations."/".proxyPass = "http://localhost:3001";
      };
      "grafana.labhome.work" = {
        forceSSL = true;
        sslCertificate = config.my.security.ssl.certPath;
        sslCertificateKey = config.my.security.ssl.keyPath;
        extraConfig = "add_header Strict-Transport-Security \"max-age=31536000; includeSubDomains\" always;";
        locations."/".proxyPass = "http://localhost:3000/";
      };
    };
  };

  # --- Prometheus Monitoring Stack ---
  services.prometheus = {
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
        job_name = "node-exporter";
        static_configs = [ { targets = [ "localhost:9100" ]; } ];
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
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3000;
        root_url = "https://grafana.labhome.work/";
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
      {
        name = "Loki";
        type = "loki";
        access = "proxy";
        url = "http://localhost:3100";
      }
    ];
  };

  # --- Uptime Kuma ---
  services.uptime-kuma = {
    enable = true;
    settings = {
      port = "3001";
      hostname = "127.0.0.1";
    };
  };

  # =================================================================
  # 6. Centralized Logging with Loki & Promtail
  # =================================================================
  services.loki = {
    enable = true;
    configuration = {
      server.http_listen_port = 3100;
      storage_config = {
      boltdb_shipper = {
        active_index_directory = "/var/lib/loki/index"; # Directory for the index
        shared_store = "filesystem";
      };
      filesystem = {
        directory = "/var/lib/loki/chunks"; # Directory for log data
      };
    };

    schema_config = {
      configs = [{
        from = "2024-01-01";
        store = "boltdb-shipper";
        object_store = "filesystem";
        schema = "v12";
        index = {
          prefix = "loki_index_";
          period = "24h";
        };
      }];
    };

    # This helps Loki manage its own data retention
    compactor = {
      working_directory = "/var/lib/loki/compactor";
      shared_store = "filesystem";
      retention_enabled = true;
      retention_delete_delay = "2h";
      delete_request_store = "filesystem";
    };
  };
};

  services.promtail = {
    enable = true;
    configuration = {
      server.http_listen_port = 0; # Promtail doesn't need to listen for connections
      clients = [ { url = "http://localhost:3100/loki/api/v1/push"; } ];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "24h";
            path = "/var/log/journal";
            labels = {
              job = "systemd-journal";
              host = config.networking.hostName;
            };
          };
          relabel_configs = [
            {
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }
          ];
        }
      ];
    };
  };

  # =================================================================
  # 7. Custom Systemd Services for Exporters
  # =================================================================
  systemd.services.cloudflare-exporter = {
    description = "Cloudflare Prometheus Exporter";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "prometheus";
      ExecStart = ''
        ${pkgs.prometheus-cloudflare-exporter}/bin/cloudflare_exporter \
          --addr "127.0.0.1:8081" \
          --token-file "${config.sops.secrets.cloudflare_prometheus_exporter_token.path}"
      '';
    };
  };
}
