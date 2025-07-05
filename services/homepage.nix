
{ config, pkgs, lib, ... }:

{
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    
    # Enhanced service configuration with correct Caddy paths
    services = [
      {
        "Media" = [
          {
            "Jellyfin" = {
              href = "http://192.168.1.165/jellyfin";  # Via Caddy
              description = "Media Server";
              icon = "jellyfin";
            };
          }
          {
            "Audiobookshelf" = {
              href = "http://192.168.1.165/audiobookshelf";  # Via Caddy
              description = "Audiobook & Podcast Server";
              icon = "audiobookshelf";
            };
          }
          {
            "Deluge" = {
              href = "http://192.168.1.165:8112";  # Direct access
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
              href = "http://192.168.1.165/nextcloud";  # Via Caddy
              description = "File Storage & Collaboration";
              icon = "nextcloud";
            };
          }
          {
            "Paperless" = {
              href = "http://192.168.1.165/paperless";  # Via Caddy
              description = "Document Management";
              icon = "paperless-ngx";
            };
          }
          {
            "Simple File Server" = {
              href = "http://192.168.1.165:8087";  # Direct access
              description = "Static File Server";
              icon = "folder";
            };
          }
          {
            "Samba" = {
              href = "smb://192.168.1.165";  # SMB protocol
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
              href = "http://192.168.1.165/microbin";  # Via Caddy
              description = "Pastebin Service";
              icon = "microbin";
            };
          }
          {
            "Miniflux" = {
              href = "http://192.168.1.165/miniflux";  # Via Caddy
              description = "RSS Reader";
              icon = "rss";
            };
          }
          {
            "Radicale" = {
              href = "http://192.168.1.165:5232";  # Direct access
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
              href = "http://192.168.1.165/grafana";  # Via Caddy ✅
              description = "Monitoring Dashboard";
              icon = "grafana";
            };
          }
          {
            "Prometheus" = {
              href = "http://192.168.1.165:9090";  # Direct access
              description = "Metrics Collection";
              icon = "prometheus";
            };
          }
          {
            "Node Exporter" = {
              href = "http://192.168.1.165:9100/metrics";  # Direct access
              description = "System Metrics";
              icon = "prometheus";
            };
          }
          {
            "Netdata" = {
              href = "http://192.168.1.165:19999";  # Direct access
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
              href = "http://192.168.1.165/hass";  # Via Caddy
              description = "Home Automation";
              icon = "home-assistant";
            };
          }
          {
            "Mosquitto MQTT" = {
              href = "http://192.168.1.165:1883";  # Direct access
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
              href = "http://192.168.1.165:8080";  # Direct access
              description = "Identity & Access Management";
              icon = "keycloak";
            };
          }
          {
            "Caddy Admin" = {
              href = "http://192.168.1.165:2019";  # Direct access
              description = "Reverse Proxy Admin";
              icon = "caddy";
            };
          }
          {
            "PostgreSQL" = {
              href = "#";  # No web interface
              description = "Database Server (CLI only)";
              icon = "postgresql";
            };
          }
          {
            "Tailscale" = {
              href = "https://login.tailscale.com/admin/machines";  # External
              description = "Mesh VPN Administration";
              icon = "tailscale";
            };
          }
          {
            "Fail2ban" = {
              href = "#";  # No web interface
              description = "Intrusion Prevention (CLI only)";
              icon = "shield";
            };
          }
        ];
      }
    ];

    # Add widgets for system monitoring
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

    # Add bookmarks for external services
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
  
  # Override environment variables
  systemd.services.homepage-dashboard.environment = {
    HOMEPAGE_ALLOWED_HOSTS = lib.mkForce "localhost,127.0.0.1,192.168.1.165,homeserver.local";
  };
  
  networking.firewall.allowedTCPPorts = [ 8082 ];
}