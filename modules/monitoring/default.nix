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
    3031 # Promtail
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
      "prometheus.example.com" = {
        forceSSL = true;
        sslCertificate = config.my.security.ssl.certPath;
        sslCertificateKey = config.my.security.ssl.keyPath;
        locations."/".proxyPass = "http://localhost:9090";
      };
      "uptime-kuma.example.com" = {
        forceSSL = true;
        sslCertificate = config.my.security.ssl.certPath;
        sslCertificateKey = config.my.security.ssl.keyPath;
        locations."/".proxyPass = "http://localhost:3001";
      };
      "grafana.example.com" = {
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
        root_url = "https://grafana.example.com/";
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
  # In your monitoring.nix file

   services.loki = {
    enable = true;
    configuration = {
      server.http_listen_port = 3100;
      auth_enabled = false;

      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore = {
              store = "inmemory";
            };
            replication_factor = 1;
          };
          # MOVED: max_transfer_retries now lives under the lifecycler
          max_transfer_retries = 0;
        };
        chunk_idle_period = "1h";
        max_chunk_age = "1h";
        chunk_target_size = 999999;
        chunk_retain_period = "30s";
        # REMOVED: max_transfer_retries was moved.
      };

      schema_config = {
        configs = [{
          from = "2022-06-06";
          store = "boltdb-shipper";
          object_store = "filesystem";
          schema = "v11";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }];
      };

      storage_config = {
        boltdb_shipper = {
          active_index_directory = "/var/lib/loki/boltdb-shipper-active";
          cache_location = "/var/lib/loki/boltdb-shipper-cache";
          cache_ttl = "24h";
          # REMOVED: This is now inferred from the top-level object_store (filesystem).
          # shared_store = "filesystem";
        };

        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };

      limits_config = {
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
        # MOVED: max_look_back_period now lives under limits_config.
        max_look_back_period = "0s";
      };

      # REMOVED: This block is no longer needed as the setting was moved.
      # chunk_store_config = {
      #   max_look_back_period = "0s";
      # };

      table_manager = {
        retention_deletes_enabled = false;
        retention_period = "0s";
      };

      compactor = {
        working_directory = "/var/lib/loki";
        # REMOVED: This is now inferred from the top-level object_store (filesystem).
        # shared_store = "filesystem";
        compactor_ring = {
          kvstore = {
            store = "inmemory";
          };
        };
      };
    };
  };


  
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3031;
        grpc_listen_port = 0;
      };
      positions = {
        filename = "/tmp/positions.yaml";
      };
      clients = [{
        url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
      }];
      scrape_configs = [{
        job_name = "journal";
        journal = {
          max_age = "12h";
          labels = {
            job = "systemd-journal";
            host = "pihole";
          };
        };
        relabel_configs = [{
          source_labels = [ "__journal__systemd_unit" ];
          target_label = "unit";
        }];
      }];
    };
    # extraFlags
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
