{ config, pkgs, ... }:
{
  # Grafana configuration for security monitoring
  services.grafana = {
    # Your existing grafana config...
    
    provision = {
      enable = true;
      
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          # Your existing datasources...
          
          {
            name = "Security Metrics";
            type = "marcusolsson-json-datasource";
            access = "proxy";
            url = "file:///var/lib/grafana/security-metrics.json";
            isDefault = false;
            jsonData = {
              cacheDurationSeconds = 300;
              httpMethod = "GET";
            };
          }
        ];
      };
      
      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "Security Dashboard";
            orgId = 1;
            folder = "Security";
            type = "file";
            disableDeletion = false;
            updateIntervalSeconds = 300;
            allowUiUpdates = true;
            options = {
              path = "/var/lib/grafana/dashboards/security";
            };
          }
        ];
      };
    };
  };
  
  # Install JSON datasource plugin
  environment.systemPackages = with pkgs; [
    (grafana.overrideAttrs (oldAttrs: {
      buildInputs = oldAttrs.buildInputs or [] ++ [
        # Add JSON datasource plugin
      ];
    }))
  ];
  
  # Create security dashboard
  systemd.services.grafana-security-dashboard = {
    description = "Create Grafana Security Dashboard";
    after = [ "grafana.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "create-security-dashboard" ''
        # Create dashboard directory
        mkdir -p /var/lib/grafana/dashboards/security
        
        # Create security dashboard JSON
        cat > /var/lib/grafana/dashboards/security/security-overview.json << 'EOF'
        {
          "dashboard": {
            "id": null,
            "title": "Security Overview",
            "tags": ["security", "monitoring"],
            "timezone": "browser",
            "refresh": "30s",
            "time": {
              "from": "now-1h",
              "to": "now"
            },
            "panels": [
              {
                "id": 1,
                "title": "Failed Login Attempts (24h)",
                "type": "stat",
                "targets": [
                  {
                    "datasource": "Security Metrics",
                    "fields": [
                      {
                        "jsonPath": "$.metrics.failed_logins_24h"
                      }
                    ]
                  }
                ],
                "fieldConfig": {
                  "defaults": {
                    "color": {
                      "mode": "thresholds"
                    },
                    "thresholds": {
                      "steps": [
                        {"color": "green", "value": null},
                        {"color": "yellow", "value": 5},
                        {"color": "red", "value": 20}
                      ]
                    }
                  }
                },
                "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0}
              },
              {
                "id": 2,
                "title": "System Resource Usage",
                "type": "gauge",
                "targets": [
                  {
                    "datasource": "Security Metrics",
                    "fields": [
                      {"jsonPath": "$.metrics.memory_usage_percent"},
                      {"jsonPath": "$.metrics.cpu_usage_percent"},
                      {"jsonPath": "$.metrics.disk_root_usage_percent"}
                    ]
                  }
                ],
                "fieldConfig": {
                  "defaults": {
                    "max": 100,
                    "min": 0,
                    "unit": "percent",
                    "thresholds": {
                      "steps": [
                        {"color": "green", "value": null},
                        {"color": "yellow", "value": 70},
                        {"color": "red", "value": 90}
                      ]
                    }
                  }
                },
                "gridPos": {"h": 8, "w": 12, "x": 6, "y": 0}
              },
              {
                "id": 3,
                "title": "Security Events Timeline",
                "type": "timeseries",
                "targets": [
                  {
                    "datasource": "Security Metrics",
                    "fields": [
                      {"jsonPath": "$.metrics.failed_ssh_1h"},
                      {"jsonPath": "$.metrics.sudo_commands_24h"},
                      {"jsonPath": "$.metrics.fail2ban_banned_ips"}
                    ]
                  }
                ],
                "gridPos": {"h": 8, "w": 18, "x": 0, "y": 8}
              },
              {
                "id": 4,
                "title": "System Health Status",
                "type": "table",
                "targets": [
                  {
                    "datasource": "Security Metrics",
                    "fields": [
                      {"jsonPath": "$.metrics.failed_services"},
                      {"jsonPath": "$.metrics.uptime_hours"},
                      {"jsonPath": "$.metrics.zfs_health_status"},
                      {"jsonPath": "$.metrics.cpu_temperature_celsius"}
                    ]
                  }
                ],
                "gridPos": {"h": 8, "w": 6, "x": 18, "y": 0}
              }
            ]
          }
        }
        EOF
        
        # Set ownership
        chown -R grafana:grafana /var/lib/grafana/dashboards
        chmod -R 644 /var/lib/grafana/dashboards/security/*.json
        
        echo "Security dashboard created"
      '';
    };
  };
}