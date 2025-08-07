{
  config,
  pkgs,
  lib,
  ...
}:

{

  sops.secrets = {
    grafana_admin_password = {
      sopsFile = ../../secrets/grafana.yaml;
      key = "grafana_admin_password";
      owner = config.users.users.grafana.name;
      group = config.users.groups.grafana.name;
      mode = "0400";
    };
    grafana_db_password = {
      sopsFile = ../../secrets/postgresql.yaml;
      key = "grafana_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
    cloudflare_prometheus_exporter_token = {
      sopsFile = ../../secrets/cloudflare-prometheus-exporter.yaml;
      key = "cloudflare_prometheus_exporter_token";
      owner = config.users.users.prometheus.name;
      group = config.users.groups.prometheus.name;
      mode = "0400";
    };
  };

  users.users = {
    grafana = {
      isSystemUser = true;
      group = "grafana";
      extraGroups = [ "users" ];
    };
    uptime-kuma = {
      isSystemUser = true;
      group = "uptime-kuma";
      extraGroups = [
        "users"
        "podman"
      ];
    };
    prometheus = {
      isSystemUser = true;
      group = "prometheus";
      extraGroups = [ "users" ];
    };
  };

  users.groups = {
    grafana = { };
    uptime-kuma = { };
    prometheus = { };
  };

  networking.firewall.allowedTCPPorts = [
    3000 # Grafana
    9090 # Prometheus
    9100 # Node Exporter
    9948 # NextDNS Exporter
    9187 # PostgreSQL Exporter
    3001 # Uptime Kuma
    8081 # Cloudflare Exporter
  ];

  environment.systemPackages = with pkgs; [
    prometheus-node-exporter
    prometheus-postgres-exporter
    grafana
    uptime-kuma
    prometheus-cloudflare-exporter
  ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      "prometheus.labhome.work" = {
        forceSSL = true;
        sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
        sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
        locations."/" = {
          proxyPass = "http://localhost:9090";
          proxyWebsockets = true;
        };
      };
      "uptime-kuma.labhome.work" = {
        forceSSL = true;
        sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
        sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
        locations."/" = {
          proxyPass = "http://localhost:3001";
          proxyWebsockets = true;
        };
      };
      "grafana.labhome.work" = {
        forceSSL = true;
        sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
        sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
        locations."/grafana/" = {
          # FIX: Added trailing slash to correctly handle the subpath
          proxyPass = "http://localhost:3000/";
          proxyWebsockets = true;
        };
      };
    };
  };

  services.prometheus = {
    enable = true;
    port = 9090;
    globalConfig = {
      scrape_interval = "15s";
      evaluation_interval = "15s";
    };

    retentionTime = "30d";

    scrapeConfigs = [
      {
        job_name = "node-exporter";
        static_configs = [
          {
            targets = [ "localhost:9100" ];
            labels = {
              instance = "homeserver";
            };
          }
        ];
        scrape_interval = "2s";
      }
      {
        job_name = "prometheus";
        static_configs = [
          {
            targets = [ "localhost:9090" ];
            labels = {
              instance = "homeserver";
            };
          }
        ];
      }
      {
        job_name = "nextdns-exporter";
        static_configs = [
          {
            targets = [ "localhost:9948" ];
            labels = {
              instance = "homeserver";
            };
          }
        ];
      }
      {
        job_name = "postgres-exporter";
        static_configs = [
          {
            targets = [ "localhost:9187" ];
            labels = {
              instance = "homeserver";
            };
          }
        ];
      }
      {
        job_name = "cloudflare-exporter";
        static_configs = [
          {
            targets = [ "localhost:8081" ];
            labels = {
              instance = "homeserver";
            };
          }
        ];
      }

    ];

    exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "systemd"
          "processes"
          "interrupts"
          "cpu"
          "zfs"
          "diskstats"
          "meminfo"
          "netdev"
          "netstat"
          "stat"
          "time"
          "thermal_zone"
          "hwmon"
        ];
        port = 9100;
      };

      postgres = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9187;
      };

      # cloudflare = {
      #   enable = true;
      #   port = 27196;
      #   extraFlags = [
      #     "--cloudflare.api-token=${config.sops.secrets.cloudflare_prometheus_exporter_token.path}"
      #     "--cloudflare.zone-id=${config.sops.secrets.cloudflare_zone_id.path}"
      #   ];
      # };
    };

    ruleFiles = [
      (pkgs.writeText "homeserver-alerts.yml" ''
        groups:
          - name: homeserver
            rules:
              - alert: HighCPUUsage
                expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
                for: 5m
                labels:
                  severity: warning
                annotations:
                  summary: "High CPU usage detected"
      '')
    ];
  };

  services.grafana = {
    enable = true;
    dataDir = "/var/lib/grafana";
    settings = {
      server = {
        http_port = 3000;
        http_addr = "0.0.0.0";
        root_url = "http://127.0.0.1:3000";
      };
      database = {
        type = "postgres";
        host = "/run/postgresql";
        user = "grafana";
        passwordFile = config.sops.secrets.grafana_db_password.path;
      };
      security = {
        admin_user = "admin";
        admin_password_file = config.sops.secrets.grafana_admin_password.path;
      };
    };

    provision.dashboards.settings.providers = [
      {
        name = "Custom Dashboards";
        type = "file";
        options.path = ./.;
        options.foldersFromFilesStructure = true;
      }
    ];
  };

  services.uptime-kuma = {
    enable = true;
    settings = {
      port = "3001";
      bind_address = "127.0.0.1";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/grafana 0755 grafana grafana -"
    "d /var/lib/grafana/dashboards 0755 grafana grafana -"
  ];
}

# services.prometheus = {
#   # ...existing config...

#   exporters = {
#     node = {
#       enable = true;
#       enabledCollectors = [
#         "systemd"
#         "processes"
#         "interrupts"
#         "cpu"
#         "zfs"
#         "diskstats"
#         "meminfo"
#         "netdev"
#         "netstat"
#         "stat"
#         "time"
#         "thermal_zone"
#         "hwmon"
#         "textfile"  # ADD: Enable textfile collector for custom metrics
#       ];
#       port = 9100;

#       # ADD: Configure textfile directory
#       extraFlags = [
#         "--collector.textfile.directory=/var/lib/prometheus-node-exporter-text-files"
#       ];
#     };
#     # ...existing exporters...
#   };
# };

# # ADD: Create textfile directory
# systemd.tmpfiles.rules = [
#   "d /var/lib/grafana 0755 grafana grafana -"
#   "d /var/lib/grafana/dashboards 0755 grafana grafana -"
#   "d /var/lib/prometheus-node-exporter-text-files 0755 prometheus prometheus -"  # ADD
# ];

# # ADD: Security metrics exporter service
# systemd.services.security-metrics-exporter = {
#   description = "Export security metrics for Prometheus";
#   serviceConfig = {
#     Type = "oneshot";
#     User = "prometheus";
#     Group = "prometheus";
#     ExecStart = pkgs.writeShellScript "security-metrics-exporter" ''
#       TEXTFILE_DIR="/var/lib/prometheus-node-exporter-text-files"

#       # Generate security metrics in Prometheus format
#       {
#         # Failed login attempts (last 24h)
#         echo "# HELP security_failed_logins_24h Failed login attempts in last 24 hours"
#         echo "# TYPE security_failed_logins_24h gauge"
#         FAILED_LOGINS=$(journalctl --since "24 hours ago" --no-pager | grep -i "failed.*password\|authentication failure" | wc -l)
#         echo "security_failed_logins_24h $FAILED_LOGINS"

#         # Failed SSH attempts (last 1h)
#         echo "# HELP security_failed_ssh_1h Failed SSH attempts in last hour"
#         echo "# TYPE security_failed_ssh_1h gauge"
#         FAILED_SSH=$(journalctl --since "1 hour ago" --no-pager | grep -i "failed password.*ssh\|invalid user.*ssh" | wc -l)
#         echo "security_failed_ssh_1h $FAILED_SSH"

#         # Sudo commands (last 24h)
#         echo "# HELP security_sudo_commands_24h Sudo commands executed in last 24 hours"
#         echo "# TYPE security_sudo_commands_24h gauge"
#         SUDO_COUNT=$(journalctl --since "24 hours ago" --no-pager | grep "sudo.*COMMAND" | wc -l)
#         echo "security_sudo_commands_24h $SUDO_COUNT"

#         # Failed systemd services
#         echo "# HELP security_failed_services Currently failed systemd services"
#         echo "# TYPE security_failed_services gauge"
#         FAILED_SERVICES=$(systemctl --failed --no-legend | wc -l)
#         echo "security_failed_services $FAILED_SERVICES"

#         # Fail2ban banned IPs
#         echo "# HELP security_banned_ips Currently banned IP addresses by fail2ban"
#         echo "# TYPE security_banned_ips gauge"
#         if systemctl is-active --quiet fail2ban 2>/dev/null; then
#           BANNED_IPS=$(${pkgs.fail2ban}/bin/fail2ban-client status 2>/dev/null | grep "Jail list:" | cut -d: -f2 | tr ',' '\n' | while read jail; do
#             if [ -n "$(echo $jail | tr -d ' ')" ]; then
#               ${pkgs.fail2ban}/bin/fail2ban-client status "$(echo $jail | tr -d ' ')" 2>/dev/null | grep "Currently banned:" | awk '{print $3}'
#             fi
#           done | awk '{sum+=$1} END {print sum+0}')
#           echo "security_banned_ips ''${BANNED_IPS:-0}"
#         else
#           echo "security_banned_ips 0"
#         fi

#         # Active network connections
#         echo "# HELP security_active_connections Current active network connections"
#         echo "# TYPE security_active_connections gauge"
#         ACTIVE_CONNECTIONS=$(ss -tuln | grep -v '127.0.0.1\|::1' | wc -l)
#         echo "security_active_connections $ACTIVE_CONNECTIONS"

#         # System uptime in hours
#         echo "# HELP security_uptime_hours System uptime in hours"
#         echo "# TYPE security_uptime_hours gauge"
#         UPTIME_HOURS=$(awk '{print int($1/3600)}' /proc/uptime)
#         echo "security_uptime_hours $UPTIME_HOURS"

#         # Open listening ports
#         echo "# HELP security_listening_ports Number of listening ports"
#         echo "# TYPE security_listening_ports gauge"
#         LISTENING_PORTS=$(ss -tln | awk 'NR>1 {print $4}' | cut -d: -f2 | sort -n | uniq | wc -l)
#         echo "security_listening_ports $LISTENING_PORTS"

#       } > "$TEXTFILE_DIR/security.prom.$$"
#       mv "$TEXTFILE_DIR/security.prom.$$" "$TEXTFILE_DIR/security.prom"
#     '';

#     PrivateTmp = true;
#     ProtectHome = true;
#     ProtectSystem = "strict";
#     ReadWritePaths = [ "/var/lib/prometheus-node-exporter-text-files" ];
#   };
# };

# systemd.timers.security-metrics-exporter = {
#   wantedBy = [ "timers.target" ];
#   timerConfig = {
#     OnCalendar = "*:0/5";  # Every 5 minutes
#     Persistent = true;
#     AccuracySec = "30s";
#   };
# };

# services.prometheus = {
#   # ...existing config...

#   ruleFiles = [
#     (pkgs.writeText "homeserver-alerts.yml" ''
#       groups:
#         - name: homeserver-system
#           rules:
#             - alert: HighCPUUsage
#               expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
#               for: 5m
#               labels:
#                 severity: warning
#               annotations:
#                 summary: "High CPU usage detected on {{ $labels.instance }}"
#                 description: "CPU usage is above 80% for more than 5 minutes"

#         # ADD: Security monitoring alerts
#         - name: security-alerts
#           rules:
#             - alert: HighFailedLogins
#               expr: security_failed_logins_24h > 20
#               for: 0m
#               labels:
#                 severity: warning
#               annotations:
#                 summary: "High number of failed login attempts"
#                 description: "{{ $value }} failed login attempts in the last 24 hours"

#             - alert: CriticalFailedLogins
#               expr: security_failed_logins_24h > 50
#               for: 0m
#               labels:
#                 severity: critical
#               annotations:
#                 summary: "Critical: Very high number of failed login attempts"
#                 description: "{{ $value }} failed login attempts in the last 24 hours - possible brute force attack"

#             - alert: RecentSSHFailures
#               expr: security_failed_ssh_1h > 5
#               for: 0m
#               labels:
#                 severity: warning
#               annotations:
#                 summary: "Recent SSH login failures detected"
#                 description: "{{ $value }} SSH login failures in the last hour"

#             - alert: SystemServicesDown
#               expr: security_failed_services > 0
#               for: 1m
#               labels:
#                 severity: critical
#               annotations:
#                 summary: "System services have failed"
#                 description: "{{ $value }} systemd services are in failed state"

#             - alert: SuspiciousActivity
#               expr: security_sudo_commands_24h > 50
#               for: 0m
#               labels:
#                 severity: warning
#               annotations:
#                 summary: "High sudo command activity"
#                 description: "{{ $value }} sudo commands executed in last 24 hours"

#             - alert: TooManyConnections
#               expr: security_active_connections > 100
#               for: 5m
#               labels:
#                 severity: warning
#               annotations:
#                 summary: "High number of active network connections"
#                 description: "{{ $value }} active network connections detected"
#     '')
#   ];
# };

# services.grafana = {
#   # ...existing config...

#   provision = {
#     enable = true;

#     datasources.settings = {
#       apiVersion = 1;
#       datasources = [
#         {
#           name = "Prometheus";
#           type = "prometheus";
#           access = "proxy";
#           url = "http://localhost:9090";
#           isDefault = true;
#         }
#       ];
#     };

#     dashboards.settings = {
#       apiVersion = 1;
#       providers = [
#         {
#           name = "Security Dashboard";
#           orgId = 1;
#           folder = "Security";
#           type = "file";
#           disableDeletion = false;
#           updateIntervalSeconds = 30;
#           allowUiUpdates = true;
#           options = {
#             path = "/var/lib/grafana/dashboards/security";
#           };
#         }
#         {
#           name = "Custom Dashboards";
#           type = "file";
#           options.path = ./.;
#           options.foldersFromFilesStructure = true;
#         }
#       ];
#     };
#   };
# };

# # ADD: Security dashboard creation service
# systemd.services.create-security-dashboard = {
#   description = "Create Grafana Security Dashboard";
#   after = [ "grafana.service" ];
#   wantedBy = [ "multi-user.target" ];
#   serviceConfig = {
#     Type = "oneshot";
#     RemainAfterExit = true;
#     User = "grafana";
#     Group = "grafana";
#     ExecStart = pkgs.writeShellScript "create-security-dashboard" ''
#       # Create dashboard directory
#       mkdir -p /var/lib/grafana/dashboards/security

#       # Create security dashboard JSON
#       cat > /var/lib/grafana/dashboards/security/security-overview.json << 'EOF'
#       {
#         "dashboard": {
#           "id": null,
#           "uid": "security-overview",
#           "title": "Security Overview",
#           "tags": ["security", "monitoring"],
#           "timezone": "browser",
#           "refresh": "30s",
#           "time": {
#             "from": "now-6h",
#             "to": "now"
#           },
#           "panels": [
#             {
#               "id": 1,
#               "title": "Failed Login Attempts (24h)",
#               "type": "stat",
#               "targets": [
#                 {
#                   "expr": "security_failed_logins_24h",
#                   "legendFormat": "Failed Logins"
#                 }
#               ],
#               "fieldConfig": {
#                 "defaults": {
#                   "color": {
#                     "mode": "thresholds"
#                   },
#                   "thresholds": {
#                     "steps": [
#                       {"color": "green", "value": null},
#                       {"color": "yellow", "value": 10},
#                       {"color": "red", "value": 25}
#                     ]
#                   }
#                 }
#               },
#               "gridPos": {"h": 6, "w": 4, "x": 0, "y": 0}
#             },
#             {
#               "id": 2,
#               "title": "Failed Services",
#               "type": "stat",
#               "targets": [
#                 {
#                   "expr": "security_failed_services",
#                   "legendFormat": "Failed Services"
#                 }
#               ],
#               "fieldConfig": {
#                 "defaults": {
#                   "color": {
#                     "mode": "thresholds"
#                   },
#                   "thresholds": {
#                     "steps": [
#                       {"color": "green", "value": 0},
#                       {"color": "red", "value": 1}
#                     ]
#                   }
#                 }
#               },
#               "gridPos": {"h": 6, "w": 4, "x": 4, "y": 0}
#             },
#             {
#               "id": 3,
#               "title": "Banned IPs",
#               "type": "stat",
#               "targets": [
#                 {
#                   "expr": "security_banned_ips",
#                   "legendFormat": "Banned IPs"
#                 }
#               ],
#               "fieldConfig": {
#                 "defaults": {
#                   "color": {
#                     "mode": "thresholds"
#                   },
#                   "thresholds": {
#                     "steps": [
#                       {"color": "green", "value": null},
#                       {"color": "yellow", "value": 1},
#                       {"color": "orange", "value": 5}
#                     ]
#                   }
#                 }
#               },
#               "gridPos": {"h": 6, "w": 4, "x": 8, "y": 0}
#             },
#             {
#               "id": 4,
#               "title": "System Uptime (Hours)",
#               "type": "stat",
#               "targets": [
#                 {
#                   "expr": "security_uptime_hours",
#                   "legendFormat": "Uptime"
#                 }
#               ],
#               "fieldConfig": {
#                 "defaults": {
#                   "unit": "h",
#                   "color": {
#                     "mode": "thresholds"
#                   },
#                   "thresholds": {
#                     "steps": [
#                       {"color": "red", "value": null},
#                       {"color": "yellow", "value": 1},
#                       {"color": "green", "value": 24}
#                     ]
#                   }
#                 }
#               },
#               "gridPos": {"h": 6, "w": 4, "x": 12, "y": 0}
#             },
#             {
#               "id": 5,
#               "title": "Security Events Timeline",
#               "type": "timeseries",
#               "targets": [
#                 {
#                   "expr": "security_failed_ssh_1h",
#                   "legendFormat": "SSH Failures (1h)"
#                 },
#                 {
#                   "expr": "security_sudo_commands_24h",
#                   "legendFormat": "Sudo Commands (24h)"
#                 },
#                 {
#                   "expr": "security_active_connections",
#                   "legendFormat": "Active Connections"
#                 }
#               ],
#               "gridPos": {"h": 8, "w": 16, "x": 0, "y": 6}
#             },
#             {
#               "id": 6,
#               "title": "Network Security",
#               "type": "table",
#               "targets": [
#                 {
#                   "expr": "security_listening_ports",
#                   "legendFormat": "Listening Ports",
#                   "format": "table"
#                 },
#                 {
#                   "expr": "security_active_connections",
#                   "legendFormat": "Active Connections",
#                   "format": "table"
#                 },
#                 {
#                   "expr": "security_banned_ips",
#                   "legendFormat": "Banned IPs",
#                   "format": "table"
#                 }
#               ],
#               "gridPos": {"h": 8, "w": 8, "x": 16, "y": 6}
#             }
#           ]
#         }
#       }
#       EOF

#       echo "Security dashboard created successfully"
#     '';
#   };
# };

# # ADD: Enhanced systemd tmpfiles rules
# systemd.tmpfiles.rules = [
#   "d /var/lib/grafana 0755 grafana grafana -"
#   "d /var/lib/grafana/dashboards 0755 grafana grafana -"
#   "d /var/lib/grafana/dashboards/security 0755 grafana grafana -"  # ADD
#   "d /var/lib/prometheus-node-exporter-text-files 0755 prometheus prometheus -"
# ];

# # ADD: Enhanced security summary service
# systemd.services.security-summary-grafana = {
#   description = "Daily Security Summary with Grafana Annotations";
#   serviceConfig = {
#     Type = "oneshot";
#     ExecStart = pkgs.writeShellScript "security-summary-grafana" ''
#       # Generate security summary
#       TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
#       EPOCH=$(date +%s)

#       # Collect metrics
#       FAILED_LOGINS=$(journalctl --since "24 hours ago" | grep -i "failed.*password\|authentication failure" | wc -l)
#       FAILED_SERVICES=$(systemctl --failed --no-legend | wc -l)
#       MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f%%", $3*100/$2}')
#       SUDO_COUNT=$(journalctl --since "24 hours ago" | grep "sudo.*COMMAND" | wc -l)
#       UPTIME=$(uptime -p)

#       # Log to systemd journal
#       echo "=== Daily Security Summary $TIMESTAMP ===" | \
#         ${pkgs.systemd}/bin/systemd-cat -t security-summary -p info
#       echo "Failed logins (24h): $FAILED_LOGINS" | \
#         ${pkgs.systemd}/bin/systemd-cat -t security-summary -p info
#       echo "Failed services: $FAILED_SERVICES" | \
#         ${pkgs.systemd}/bin/systemd-cat -t security-summary -p info
#       echo "Memory usage: $MEMORY_USAGE" | \
#         ${pkgs.systemd}/bin/systemd-cat -t security-summary -p info
#       echo "Sudo commands (24h): $SUDO_COUNT" | \
#         ${pkgs.systemd}/bin/systemd-cat -t security-summary -p info
#       echo "System uptime: $UPTIME" | \
#         ${pkgs.systemd}/bin/systemd-cat -t security-summary -p info
#       echo "Grafana dashboard: https://grafana.labhome.work/d/security-overview" | \
#         ${pkgs.systemd}/bin/systemd-cat -t security-summary -p info

#       # Create Grafana annotation via API
#       GRAFANA_API="http://localhost:3000/api/annotations"
#       ANNOTATION_JSON=$(cat << EOF
#       {
#         "time": $(echo "$EPOCH * 1000" | bc),
#         "timeEnd": $(echo "$EPOCH * 1000" | bc),
#         "title": "Daily Security Summary",
#         "text": "Failed logins: $FAILED_LOGINS | Failed services: $FAILED_SERVICES | Memory: $MEMORY_USAGE | Sudo: $SUDO_COUNT",
#         "tags": ["security", "daily-summary"]
#       }
#       EOF
#       )

#       # Post annotation to Grafana (using admin credentials)
#       ${pkgs.curl}/bin/curl -X POST "$GRAFANA_API" \
#         -H "Content-Type: application/json" \
#         -u "admin:$(cat ${config.sops.secrets.grafana_admin_password.path})" \
#         -d "$ANNOTATION_JSON" || echo "Failed to create Grafana annotation"

#       echo "=== End Security Summary ===" | \
#         ${pkgs.systemd}/bin/systemd-cat -t security-summary -p info
#     '';
#   };
# };

# systemd.timers.security-summary-grafana = {
#   wantedBy = [ "timers.target" ];
#   timerConfig = {
#     OnCalendar = "daily";
#     Persistent = true;
#     RandomizedDelaySec = "1h";
#   };
# };
