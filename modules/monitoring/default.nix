{
  config,
  pkgs,
  ...
}: {
  # =================================================================
  # 1. SOPS Secrets
  # =================================================================
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
    9090 # Prometheus
    9100 # Node Exporter
    9199 # NUT Exporter
  ];

  # =================================================================
  # 4. GeoIP Database (db-ip.com, no account required)
  # Promtail uses this MMDB for the geoip pipeline stage on cowrie logs.
  # db_type "city" is the only type that exposes country/geo labels.
  # db-ip city-lite is MaxMind-compatible MMDB format.
  # =================================================================
  systemd.tmpfiles.rules = [
    "d /var/lib/geoip 0755 root root -"
  ];

  systemd.services.geoip-update = {
    description = "Download db-ip city MMDB for Promtail geoip enrichment";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = pkgs.writeShellScript "geoip-update" ''
        set -euo pipefail
        DEST=/var/lib/geoip/city.mmdb
        TMP=$(mktemp)
        trap 'rm -f "$TMP" "$TMP.gz"' EXIT
        ${pkgs.curl}/bin/curl -fsSL \
          "https://download.db-ip.com/free/dbip-city-lite-latest.mmdb.gz" \
          -o "$TMP.gz"
        ${pkgs.gzip}/bin/gunzip -c "$TMP.gz" > "$TMP"
        install -m 0644 "$TMP" "$DEST"
        echo "GeoIP DB updated: $(${pkgs.coreutils}/bin/stat -c %s $DEST) bytes"
      '';
    };
  };

  systemd.timers.geoip-update = {
    description = "Monthly GeoIP DB update";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  # =================================================================
  # 5. Services
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
          url = "http://localhost:3100";
        }
      ];
      provision.dashboards.settings.providers = [
        {
          name = "dashboards";
          options.path = ./dashboards;
          disableDeletion = false;
          updateIntervalSeconds = 30;
        }
      ];
    };

    # --- Loki Log Aggregation ---
    # Storage: filesystem on zroot (/var/lib/loki)
    # Retention: 30d time-based (Loki has no byte-cap; tune period to stay ~2GB)
    loki = {
      enable = true;
      configuration = {
        auth_enabled = false;

        server.http_listen_port = 3100;

        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore.store = "inmemory";
              replication_factor = 1;
            };
          };
          chunk_idle_period = "1h";
          max_chunk_age = "1h";
          chunk_target_size = 1048576;
          chunk_retain_period = "30s";
        };

        schema_config.configs = [
          {
            from = "2025-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h"; # must be 24h for compactor retention to work
            };
          }
        ];

        storage_config = {
          tsdb_shipper = {
            active_index_directory = "/var/lib/loki/tsdb-index";
            cache_location = "/var/lib/loki/tsdb-cache";
          };
          filesystem.directory = "/var/lib/loki/chunks";
        };

        compactor = {
          working_directory = "/var/lib/loki/compactor";
          compaction_interval = "10m";
          retention_enabled = true;
          retention_delete_delay = "2h";
          retention_delete_worker_count = 150;
          delete_request_store = "filesystem";
          compactor_ring.kvstore.store = "inmemory";
        };

        limits_config = {
          retention_period = "30d";
          reject_old_samples = true;
          reject_old_samples_max_age = "30d";
          ingestion_rate_mb = 4;
          ingestion_burst_size_mb = 8;
        };

        query_range.cache_results = true;
      };
    };

    # --- Promtail Log Shipper ---
    # Tails cowrie JSON, traefik access log, and systemd journal.
    # GeoIP stage enriches cowrie events with city/country labels from db-ip MMDB.
    # Note: db_type accepts only "city" or "asn" — "country" is invalid.
    # db-ip city-lite MMDB provides: geoip_country_name, geoip_city_name, geoip_continent_code, etc.
    promtail = {
      enable = true;
      configuration = {
        server = {
          http_listen_port = 9080;
          grpc_listen_port = 0;
        };
        positions.filename = "/var/cache/promtail/positions.yaml";
        clients = [{url = "http://localhost:3100/loki/api/v1/push";}];

        scrape_configs = [
          # Cowrie SSH honeypot JSON log with GeoIP enrichment
          {
            job_name = "cowrie";
            pipeline_stages = [
              {
                json.expressions = {
                  src_ip = "src_ip";
                  eventid = "eventid";
                  username = "username";
                  session = "session";
                };
              }
              {
                # Requires /var/lib/geoip/city.mmdb (downloaded by geoip-update.service)
                # Populates: geoip_country_name, geoip_city_name, geoip_continent_code, etc.
                geoip = {
                  db = "/var/lib/geoip/city.mmdb";
                  source = "src_ip";
                  db_type = "city";
                };
              }
              {
                labels = {
                  eventid = null;
                  username = null;
                  geoip_country_name = null;
                  geoip_city_name = null;
                };
              }
            ];
            static_configs = [
              {
                targets = ["localhost"];
                labels = {
                  job = "cowrie";
                  host = "homeserver";
                  "__path__" = "/var/log/cowrie/cowrie.json";
                };
              }
            ];
          }

          # Traefik access log
          {
            job_name = "traefik";
            static_configs = [
              {
                targets = ["localhost"];
                labels = {
                  job = "traefik";
                  host = "homeserver";
                  "__path__" = "/var/log/traefik/access.log";
                };
              }
            ];
          }

          # Systemd journal
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = "homeserver";
              };
            };
            relabel_configs = [
              {
                source_labels = ["__journal__systemd_unit"];
                target_label = "unit";
              }
            ];
          }
        ];
      };
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
        {
          job_name = "prometheus";
          static_configs = [{targets = ["localhost:${toString config.my.network.ports.prometheus}"];}];
        }
        {
          job_name = "traefik";
          static_configs = [{targets = ["localhost:8080"];}];
        }
        {
          job_name = "cowrie";
          static_configs = [{targets = ["localhost:9001"];}];
        }
      ];
    };
  };
}
