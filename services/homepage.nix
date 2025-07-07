{ config, pkgs, lib, ... }:

{
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;

    # Enhanced service configuration with external domain URLs
    services = [
      {
        "Media" = [
          {
            "Jellyfin" = {
              href = "https://jellyfin.labhome.work";
              description = "Media Server";
              icon = "jellyfin";
            };
          }
          {
            "Audiobookshelf" = {
              href = "http://192.168.1.165/audiobookshelf";
              description = "Audiobook & Podcast Server";
              icon = "audiobookshelf";
            };
          }
          {
            "Transmission" = {
              href = "http://192.168.1.165:9091";
              description = "Torrent Client (VPN)";
              icon = "transmission";
            };
          }
        ];
      }
      {
        "Storage & Documents" = [
          {
            "Nextcloud" = {
              href = "https://nextcloud.labhome.work/";
              description = "File Storage & Collaboration";
              icon = "nextcloud";
            };
          }
          {
            "Paperless" = {
              href = "https://paperless.labhome.work";
              description = "Document Management";
              icon = "paperless-ngx";
            };
          }
          {
            "Samba" = {
              href = "smb://192.168.1.165";
              description = "Network File Share";
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/samba-server.svg";
            };
          }
        ];
      }
      {
        "Productivity Tools" = [
          {
            "Microbin" = {
              href = "http://192.168.1.165/microbin";
              description = "Pastebin Service";
              icon = "microbin";
            };
          }
          {
            "Miniflux" = {
              href = "http://192.168.1.165/miniflux";
              description = "RSS Reader";
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/miniflux.svg";
            };
          }
          {
            "Radicale" = {
              href = "https://cal.labhome.work";
              description = "Calendar & Contacts";
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/radicale.svg";
            };
          }
        ];
      }
      # Update the monitoring section to use working tools:
      {
        "Monitoring & Analytics" = [
          {
            "Grafana" = {
              href = "http://192.168.1.165:3000";
              description = "Real-time System Dashboard";
              icon = "grafana";
            };
          }
          {
            "Prometheus" = {
              href = "http://192.168.1.165:9090";
              description = "Metrics & Alerting";
              icon = "prometheus";
            };
          }
          {
            "Node Exporter" = {
              href = "http://192.168.1.165:9100/metrics";
              description = "System Metrics (Raw)";
              icon = "prometheus";
            };
          }
        ];
      }
      {
        "Smart Home & IoT" = [
          {
            "Home Assistant" = {
              href = "https://home.labhome.work";
              description = "Home Automation";
              icon = "home-assistant";
            };
          }
          {
            "Mosquitto MQTT" = {
              href = "http://192.168.1.165:1883";
              description = "MQTT Broker";
              icon = "mqtt";
            };
          }
        ];
      }
      {
        "Infrastructure & Security" = [
          {
            "Keycloak" = {
              href = "https://keycloak.labhome.work";
              description = "Identity & Access Management";
              icon = "keycloak";
            };
          }
          {
            "Caddy Admin" = {
              href = "http://192.168.1.165:2019";
              description = "Reverse Proxy Admin";
              icon = "caddy";
            };
          }
          {
            "PostgreSQL" = {
              href = "#";
              description = "Database Server (CLI only)";
              icon = "postgresql";
            };
          }
          {
            "Tailscale" = {
              href = "https://login.tailscale.com/admin/machines";
              description = "Mesh VPN Administration";
              icon = "tailscale";
            };
          }
          {
            "Fail2ban" = {
              href = "#";
              description = "Intrusion Prevention (CLI only)";
              icon = "https://upload.wikimedia.org/wikipedia/commons/d/db/Fail2ban_logo.png";
            };
          }
        ];
      }
    ];

    widgets = [
      {
        "system" = {
          "cpu" = true;
          "memory" = true;
          "disk" = "/";
        };
      }
      {
        "datetime" = {
          "text_size" = "xl";
          "format" = {
            "dateStyle" = "long";
            "timeStyle" = "short";
            "hour12" = false;
          };
        };
      }
    ];

    bookmarks = [
      {
        "External Services" = [
          {
            "Cloudflare" = [
              {
                "name" = "Dashboard";
                "href" = "https://dash.cloudflare.com";
              }
              {
                "name" = "Zero Trust";
                "href" = "https://one.dash.cloudflare.com";
              }
            ];
          }
          {
            "Tailscale" = [
              {
                "name" = "Admin Console";
                "href" = "https://login.tailscale.com/admin";
              }
              {
                "name" = "ACL Editor";
                "href" = "https://login.tailscale.com/admin/acls";
              }
            ];
          }
          {
            "GitHub" = [
              {
                "name" = "Server Config";
                "href" = "https://github.com/your-username/server-config";
              }
            ];
          }
        ];
      }
    ];
  };

  systemd.services.homepage-dashboard.environment = {
    HOMEPAGE_ALLOWED_HOSTS = lib.mkForce "localhost,127.0.0.1,192.168.1.165,homeserver.local";
  };

  # REMOVED: Firewall port (now handled centrally in networking.nix)
}