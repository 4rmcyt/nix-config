{ config, pkgs, lib, ... }:

{
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;

    # Enhanced service configuration with mixed access methods
    services = [
      {
        "Media" = [
          {
            "Jellyfin" = {
              href = "http://192.168.1.165/jellyfin";
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
            "Deluge" = {
              href = "http://192.168.1.165:8112";
              description = "Torrent Client (VPN)";
              icon = "deluge";
            };
          }
        ];
      }
      {
        "Storage & Documents" = [
          {
            "Nextcloud" = {
              href = "http://192.168.1.165/nextcloud";
              description = "File Storage & Collaboration";
              icon = "nextcloud";
            };
          }
          {
            "Paperless" = {
              href = "http://192.168.1.165/paperless";
              description = "Document Management";
              icon = "paperless-ngx";
            };
          }
          {
            "Simple File Server" = {
              href = "http://192.168.1.165:8087";
              description = "Static File Server";
              icon = "folder";
            };
          }
          {
            "Samba" = {
              href = "smb://192.168.1.165";
              description = "Network File Share";
              icon = "samba";
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
              icon = "rss";
            };
          }
          {
            "Radicale" = {
              href = "http://192.168.1.165:5232";
              description = "Calendar & Contacts";
              icon = "calendar";
            };
          }
        ];
      }
      {
        "Monitoring & Analytics" = [
          {
            "Grafana" = {
              href = "http://192.168.1.165:3000";  # Direct access - simpler and reliable
              description = "Monitoring Dashboard";
              icon = "grafana";
            };
          }
          {
            "Prometheus" = {
              href = "http://192.168.1.165:9090";
              description = "Metrics Collection";
              icon = "prometheus";
            };
          }
          {
            "Node Exporter" = {
              href = "http://192.168.1.165:9100/metrics";
              description = "System Metrics";
              icon = "prometheus";
            };
          }
          {
            "Netdata" = {
              href = "http://192.168.1.165:19999";
              description = "Real-time System Monitor";
              icon = "netdata";
            };
          }
        ];
      }
      {
        "Smart Home & IoT" = [
          {
            "Home Assistant" = {
              href = "http://192.168.1.165/hass";
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
              icon = "shield";
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
  
  networking.firewall.allowedTCPPorts = [ 8082 ];
}