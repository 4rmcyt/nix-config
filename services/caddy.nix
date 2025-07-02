{ config, pkgs, ... }:

{
  services.caddy = {
    enable = true;
    
    # Global Caddy configuration
    globalConfig = ''
      # Global settings
      admin off
      auto_https off
      
      # Logging
      log {
        output file /var/log/caddy/access.log {
          roll_size 100mb
          roll_keep 5
        }
        format json
      }
    '';
    
    virtualHosts = {
      # Nextcloud
      "nextcloud.yourdomain.com" = {
        extraConfig = ''
          reverse_proxy localhost:8080 {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };
      
      # Keycloak
      "keycloak.yourdomain.com" = {
        extraConfig = ''
          reverse_proxy localhost:8081 {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };
      
      # Jellyfin
      "jellyfin.yourdomain.com" = {
        extraConfig = ''
          reverse_proxy localhost:8096 {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };
      
      # Paperless
      "paperless.yourdomain.com" = {
        extraConfig = ''
          reverse_proxy localhost:8082 {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };
      
      # Home Assistant
      "home.yourdomain.com" = {
        extraConfig = ''
          reverse_proxy localhost:8123 {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
            header_up X-Forwarded-Host {host}
          }
        '';
      };
      
      # Miniflux
      "rss.yourdomain.com" = {
        extraConfig = ''
          reverse_proxy localhost:8083 {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };
      
      # Deluge Web UI
      "deluge.yourdomain.com" = {
        extraConfig = ''
          reverse_proxy localhost:8112 {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };
      
      # Radicale CalDAV/CardDAV
      "cal.yourdomain.com" = {
        extraConfig = ''
          reverse_proxy localhost:5232 {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };
    };
  };

  # Create log directory
  systemd.tmpfiles.rules = [
    "d /var/log/caddy 0755 caddy caddy -"
  ];

  # Ensure Caddy can bind to privileged ports
  systemd.services.caddy.serviceConfig.AmbientCapabilities = "CAP_NET_BIND_SERVICE";
}