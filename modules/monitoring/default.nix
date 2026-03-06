{config, ...}: {
  # =================================================================
  # 1. SOPS Secrets
  # =================================================================
  # Env file for Tailscale exporter — rendered at activation, before any service starts
  # Uses "-" as tailnet (Tailscale API convention for "current user's tailnet")

  sops.secrets = {
    cloudflare_prometheus_exporter_token = {
      sopsFile = ../../secrets/cloudflare-prometheus-exporter.yaml;
      key = "cloudflare_prometheus_exporter_token";
    };
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
    loki_github_actions_token = {
      sopsFile = ../../secrets/loki.yaml;
      key = "github_actions_token";
      owner = "loki";
      mode = "0400";
    };
    tailscale_prometheus_exporter_env = {
      sopsFile = ../../secrets/tailscale-prometheus-exporter.env;
      format = "dotenv";
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
    3100 # Loki
    28183 # Promtail
    8081 # Cloudflare Exporter
    9090 # Prometheus
    9100 # Node Exporter
    9187 # PostgreSQL Exporter
    9199 # NUT Exporter
    9250 # Tailscale Exporter
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
        {
          name = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://localhost:${toString config.services.loki.configuration.server.http_listen_port}";
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
        tailscale = {
          enable = true;
          environmentFile = config.sops.secrets.tailscale_prometheus_exporter_env.path;
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
        {
          job_name = "tailscale";
          static_configs = [{targets = ["localhost:9250"];}];
        }
      ];
    };

    # --- Loki Log Aggregation ---
    loki = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 3100;
          # Listen on all interfaces to accept logs from GitHub Actions
          http_listen_address = "0.0.0.0";
        };
        auth_enabled = false;
        server.log_level = "warn";

        common = {
          ring = {
            instance_addr = "127.0.0.1";
            kvstore.store = "inmemory";
          };
          replication_factor = 1;
          path_prefix = "/var/lib/loki";
        };

        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore.store = "inmemory";
              replication_factor = 1;
            };
            final_sleep = "0s";
          };
          chunk_idle_period = "5m";
          chunk_retain_period = "30s";
        };

        schema_config = {
          configs = [
            {
              from = "2025-11-13";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                period = "24h";
                prefix = "loki_ops_index_";
              };
            }
          ];
        };

        storage_config = {
          filesystem.directory = "/var/lib/loki/chunks";
          tsdb_shipper.active_index_directory = "/var/lib/loki/tsdb-index";
          tsdb_shipper.cache_location = "/var/lib/loki/tsdb-cache";
        };

        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
          # Increase ingestion limits for GitHub Actions logs
          ingestion_rate_mb = 10;
          ingestion_burst_size_mb = 20;
        };

        ruler = {
          storage = {
            type = "local";
            local.directory = "/tmp/rules";
          };
          rule_path = "/tmp/scratch";
          alertmanager_url = "http://nuc:9093";
          ring.kvstore.store = "inmemory";
          enable_api = true;
        };

        query_scheduler = {
          max_outstanding_requests_per_tenant = 2048;
        };
      };
    };

    # --- Promtail Log Shipper ---
    promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 3031;
          grpc_listen_port = 0;
        };
        positions = {
          filename = "/tmp/positions.yaml";
        };
        clients = [
          {
            url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
          }
        ];
        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
              };
            };
            relabel_configs = [
              {
                source_labels = ["__journal__systemd_unit"];
                regex = "(.*)\\.service";
                target_label = "service";
              }
              {
                source_labels = ["__journal__hostname"];
                target_label = "hostname";
              }
            ];
          }
        ];
      };
    };
  };

  # =================================================================
  # 5. Custom Systemd Services for Exporters (future)
  # =================================================================
  # systemd.services.cloudflare-exporter = {
  #   description = "Cloudflare Prometheus Exporter";
  #   wantedBy = ["multi-user.target"];
  #   after = ["network.target"];
  #   serviceConfig = {
  #     User = "prometheus";
  #     Group = "prometheus";
  #     EnvironmentFile = config.sops.secrets.cloudflare_prometheus_exporter_token.path;
  #     ExecStart = ''
  #       ${pkgs.prometheus-cloudflare-exporter}/bin/cloudflare-exporter \
  #         --listen "127.0.0.1:8081" \
  #         --cf_api_token "$CLOUDFLARE_PROMETHEUS_EXPORTER_TOKEN"
  #     '';
  #     Restart = "always";
  #     RestartSec = 10;
  #   };
  # };
}
