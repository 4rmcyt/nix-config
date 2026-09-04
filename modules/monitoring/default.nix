{
  config,
  pkgs,
  ...
}: {
  sops.secrets = {
    ntfy_alertmanager_config = {
      sopsFile = ../../secrets/ntfy.yaml;
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
      sopsFile = ../../secrets/kanidm.yaml;
      key = "kanidm_grafana_secret";
      owner = config.users.users.grafana.name;
    };
    grafana_secret_key = {
      sopsFile = ../../secrets/grafana.yaml;
      key = "grafana_secret_key";
      owner = config.users.users.grafana.name;
    };
  };

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

  networking.firewall.allowedTCPPorts = [
    config.my.network.ports.grafana
    3100 # Loki
    config.my.network.ports.prometheus
    config.my.network.ports.node-exporter
    9199 # NUT Exporter
  ];

  # GeoIP Database (db-ip.com, no account required)
  systemd.tmpfiles.rules = [
    "d /var/lib/geoip 0755 root root -"
    "d /var/lib/loki/rules 0755 loki loki -"
    "d /var/lib/loki/rules/fake 0755 loki loki -"
    "d /var/lib/loki/rules-temp 0755 loki loki -"
    "L+ /var/lib/loki/rules/fake/homeserver.yaml - - - - ${./alerts/loki-rules.yaml}"
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
    // relabel rules stored here, applied via relabel_rules= in source.journal
    loki.relabel "journal" {
      forward_to = []
      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
      // __journal_priority_keyword: emerg, alert, crit, error, warning, notice, info, debug
      rule {
        source_labels = ["__journal_priority_keyword"]
        regex         = "emerg|alert|crit"
        target_label  = "level"
        replacement   = "critical"
      }
      rule {
        source_labels = ["__journal_priority_keyword"]
        regex         = "error"
        target_label  = "level"
        replacement   = "error"
      }
      rule {
        source_labels = ["__journal_priority_keyword"]
        regex         = "warning"
        target_label  = "level"
        replacement   = "warning"
      }
      rule {
        source_labels = ["__journal_priority_keyword"]
        regex         = "notice"
        target_label  = "level"
        replacement   = "notice"
      }
      rule {
        source_labels = ["__journal_priority_keyword"]
        regex         = "info"
        target_label  = "level"
        replacement   = "info"
      }
      rule {
        source_labels = ["__journal_priority_keyword"]
        regex         = "debug"
        target_label  = "level"
        replacement   = "debug"
      }
    }

    loki.source.journal "journal" {
      max_age       = "12h"
      relabel_rules = loki.relabel.journal.rules
      forward_to    = [loki.process.fix_container_level.receiver]
      labels        = {
        job  = "systemd-journal",
        host = "homeserver",
      }
    }

    // Containers (Python/celery) write INFO/DEBUG/WARNING to stderr → journald
    // marks them priority=error. Fix: for logs labelled error, check if the
    // line text starts with a Python log level and downgrade accordingly.
    loki.process "fix_container_level" {
      forward_to = [loki.write.default.receiver]

      stage.match {
        selector = "{level=\"error\"}"
        stage.regex {
          expression = "^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}[,.]\\d+ (?P<text_level>DEBUG|INFO|WARNING)"
        }
        stage.template {
          source   = "text_level"
          template = "{{ ToLower .Value }}"
        }
        stage.labels {
          values = { level = "text_level" }
        }
      }
    }
  '';

  systemd.services.alloy = {
    after = ["geoip-update.service"];
    serviceConfig.SupplementaryGroups = ["systemd-journal"];
  };

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
          http_port = config.my.network.ports.grafana;
          root_url = "https://grafana.${config.my.defaults.domain}";
        };
        "auth.generic_oauth" = {
          enabled = true;
          name = "Kanidm";
          client_id = "grafana";
          client_secret = "$__file{${config.sops.secrets.grafana_oidc_client_secret.path}}";
          scopes = "openid profile email groups";
          auth_url = "https://idm.${config.my.defaults.domain}/ui/oauth2";
          token_url = "https://idm.${config.my.defaults.domain}/oauth2/token";
          api_url = "https://idm.${config.my.defaults.domain}/oauth2/openid/grafana/userinfo";
          use_pkce = true;
          role_attribute_path = "contains(grafana_role[], 'Admin') && 'GrafanaAdmin' || 'Viewer'";
          allow_assign_grafana_admin = true;
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
          allow_structured_metadata = false;
        };
        query_range.cache_results = true;
        frontend.scheduler_address = "";
        frontend_worker.scheduler_address = "";
        ruler = {
          storage = {
            type = "local";
            local.directory = "/var/lib/loki/rules";
          };
          rule_path = "/var/lib/loki/rules-temp";
          alertmanager_url = "http://127.0.0.1:${toString config.my.network.ports.alertmanager}";
          enable_alertmanager_v2 = true;
          enable_api = true;
          ring.kvstore.store = "inmemory";
        };
      };
    };

    # --- Grafana Alloy Log Shipper ---
    alloy.enable = true;

    # --- Prometheus Monitoring Stack ---
    prometheus = {
      enable = true;
      port = config.my.network.ports.prometheus;
      retentionTime = "30d";
      globalConfig.scrape_interval = "1m";
      ruleFiles = [./alerts/homeserver.yaml];
      alertmanagers = [
        {
          static_configs = [{targets = ["127.0.0.1:${toString config.my.network.ports.alertmanager}"];}];
        }
      ];

      exporters = {
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
          static_configs = [{targets = ["localhost:${toString config.my.network.ports.node-exporter}"];}];
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
          job_name = "router-node";
          static_configs = [{targets = ["router.ts.${config.my.defaults.domain}:${toString config.my.network.ports.node-exporter}"];}];
        }
        {
          job_name = "router-unbound";
          static_configs = [{targets = ["router.ts.${config.my.defaults.domain}:9167"];}];
        }
        {
          job_name = "router-kea";
          static_configs = [{targets = ["router.ts.${config.my.defaults.domain}:9547"];}];
        }
        {
          job_name = "gcp-relay-node";
          static_configs = [{targets = ["100.64.0.5:${toString config.my.network.ports.node-exporter}"];}];
        }
        {
          job_name = "matebook-node";
          static_configs = [{targets = ["${config.my.network.hosts.matebook_wifi}:${toString config.my.network.ports.node-exporter}"];}];
        }
      ];
    };
  };

  services.prometheus.alertmanager = {
    enable = true;
    port = config.my.network.ports.alertmanager;
    listenAddress = "127.0.0.1";
    extraFlags = ["--cluster.listen-address="];
    configuration = {
      route = {
        receiver = "ntfy";
        group_wait = "30s";
        group_interval = "5m";
        repeat_interval = "4h";
      };
      receivers = [
        {
          name = "ntfy";
          webhook_configs = [
            {
              url = "http://127.0.0.1:${toString config.my.network.ports.alertmanager-ntfy}/hook";
              send_resolved = true;
            }
          ];
        }
      ];
    };
  };

  services.prometheus.alertmanager-ntfy = {
    enable = true;
    extraConfigFiles = [config.sops.secrets.ntfy_alertmanager_config.path];
    settings = {
      http.addr = "127.0.0.1:${toString config.my.network.ports.alertmanager-ntfy}";
      ntfy = {
        baseurl = "http://127.0.0.1:9991";
        notification.topic = "alerts";
      };
    };
  };
}
