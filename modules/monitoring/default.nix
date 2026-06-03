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
  # 2. NixOS generation tracking (textfile collector)
  # =================================================================
  services.prometheus.exporters.node.extraFlags = [
    "--collector.textfile.directory=/var/lib/prometheus-node-exporter-text-files"
  ];

  system.activationScripts.node-exporter-system-version = {
    supportsDryActivation = true;
    text = ''
      mkdir -pm 0775 /var/lib/prometheus-node-exporter-text-files
      (
        echo -n "system_version "
        readlink /nix/var/nix/profiles/system | cut -d- -f2
      ) > /var/lib/prometheus-node-exporter-text-files/system-version.prom.next
      mv /var/lib/prometheus-node-exporter-text-files/system-version.prom.next \
         /var/lib/prometheus-node-exporter-text-files/system-version.prom
    '';
  };

  # =================================================================
  # 3. Users and Groups
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
  # =================================================================
  systemd.tmpfiles.rules = [
    "d /var/lib/geoip 0755 root root -"
  ];

  systemd.services.geoip-update = {
    description = "Download db-ip city MMDB for Alloy geoip enrichment";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = pkgs.writeShellScript "geoip-update" ''
        set -euo pipefail
        DEST=/var/lib/geoip/city.mmdb
        YEAR_MONTH=$(${pkgs.coreutils}/bin/date +%Y-%m)
        URL="https://download.db-ip.com/free/dbip-city-lite-''${YEAR_MONTH}.mmdb.gz"
        TMP=$(${pkgs.coreutils}/bin/mktemp)
        trap 'rm -f "$TMP" "$TMP.gz"' EXIT
        ${pkgs.curl}/bin/curl -fsSL "$URL" -o "$TMP.gz"
        ${pkgs.gzip}/bin/gunzip -c "$TMP.gz" > "$TMP"
        ${pkgs.coreutils}/bin/install -m 0644 "$TMP" "$DEST"
        echo "GeoIP DB updated from $URL: $(${pkgs.coreutils}/bin/stat -c %s $DEST) bytes"
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
  # 5. Alloy config
  # =================================================================
  environment.etc."alloy/config.alloy".text = ''
    // ── Loki sink ────────────────────────────────────────────────
    loki.write "default" {
      endpoint {
        url = "http://localhost:3100/loki/api/v1/push"
      }
    }

    // ── Traefik access log ────────────────────────────────────────
    local.file_match "traefik" {
      path_targets = [{
        __path__ = "/var/log/traefik/access.log",
        job       = "traefik",
        host      = "homeserver",
      }]
    }

    loki.source.file "traefik" {
      targets    = local.file_match.traefik.targets
      forward_to = [loki.write.default.receiver]
    }

    // ── Systemd journal ───────────────────────────────────────────
    loki.source.journal "journal" {
      max_age    = "12h"
      forward_to = [loki.relabel.journal.receiver]
      labels     = {
        job  = "systemd-journal",
        host = "homeserver",
      }
    }

    loki.relabel "journal" {
      forward_to = [loki.write.default.receiver]
      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
    }
  '';

  systemd.services.alloy = {
    after = ["geoip-update.service"];
    serviceConfig.SupplementaryGroups = ["systemd-journal"];
  };

  # =================================================================
  # 6. Services
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
              period = "24h";
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
          ingestion_rate_mb = 16;
          ingestion_burst_size_mb = 32;
        };
        query_range.cache_results = true;
      };
    };

    # --- Grafana Alloy Log Shipper ---
    alloy.enable = true;

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
            "textfile"
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
          static_configs = [{targets = ["localhost:9100"];}];
        }
        {
          job_name = "nut-exporter";
          static_configs = [{targets = ["localhost:9199"];}];
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
          job_name = "crowdsec";
          static_configs = [{targets = ["localhost:6060"];}];
        }
        {
          job_name = "gcp-relay-node";
          static_configs = [{targets = ["203.0.113.1:9100"];}];
        }
        {
          job_name = "matebook-node";
          static_configs = [{targets = ["${config.my.defaults.matebook_wifi}:9100"];}];
        }
      ];
    };
  };
}
