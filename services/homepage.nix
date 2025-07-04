{ config, pkgs, lib, ... }:

{
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    
    # Enhanced service configuration
    services = [
      {
        "Media" = [
          {
            "Jellyfin" = {
              href = "http://192.168.1.165:8096";
              description = "Media Server";
              icon = "jellyfin";
            };
          }
          {
            "Audiobookshelf" = {
              href = "http://192.168.1.165:8085";
              description = "Audiobook & Podcast Server";
              icon = "audiobookshelf";
            };
          }
        ];
      }
      {
        "Storage" = [
          {
            "Nextcloud" = {
              href = "http://192.168.1.165:8081";
              description = "File Storage & Collaboration";
              icon = "nextcloud";
            };
          }
          {
            "Paperless" = {
              href = "http://192.168.1.165:8888";
              description = "Document Management";
              icon = "paperless-ngx";
            };
          }
          {
            "Simple File Server" = {
              href = "http://192.168.1.165:8084";
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
        "Tools" = [
          {
            "Microbin" = {
              href = "http://192.168.1.165:8083";
              description = "Pastebin Service";
              icon = "microbin";
            };
          }
          {
            "Miniflux" = {
              href = "http://192.168.1.165:8086";
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
        "Automation" = [
          {
            "Home Assistant" = {
              href = "http://192.168.1.165:8123";
              description = "Home Automation";
              icon = "home-assistant";
            };
          }
        ];
      }
      {
        "Networking" = [
          {
            "Keycloak" = {
              href = "http://192.168.1.165:8080";
              description = "Identity & Access Management";
              icon = "keycloak";
            };
          }
          {
            "Caddy" = {
              href = "http://192.168.1.165:2019";
              description = "Reverse Proxy Admin";
              icon = "caddy";
            };
          }
          {
            "Tailscale" = {
              href = "https://login.tailscale.com/admin/machines";
              description = "Mesh VPN";
              icon = "tailscale";
            };
          }
          {
            "Fail2ban" = {
              href = "http://192.168.1.165:8082/fail2ban"; # adjust if you have a UI
              description = "Ban List";
              icon = "shield";
            };
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
