{ config, pkgs, lib, ... }:

{
  services.caddy = {
    enable = true;
    
    # Use virtualHosts instead of extraConfig to avoid conflicts
    virtualHosts."localhost" = {
      listenAddresses = [ ":80" ];
      extraConfig = ''
        # Security headers
        header {
          Strict-Transport-Security "max-age=15768000; includeSubDomains"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "SAMEORIGIN" 
          X-XSS-Protection "1; mode=block"
          Referrer-Policy "strict-origin-when-cross-origin"
          -Server
        }

        # Compression
        encode gzip zstd

        # Audiobookshelf
        handle_path /audiobookshelf* {
          reverse_proxy localhost:8085 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        # Microbin
        handle_path /microbin* {
          reverse_proxy localhost:8083 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
          }
        }

        # Home Assistant
        handle_path /hass* {
          reverse_proxy localhost:8123 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        # Homepage dashboard
        handle_path /homepage* {
          reverse_proxy localhost:8082 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
          }
        }

        # Jellyfin
        handle_path /jellyfin* {
          reverse_proxy localhost:8096 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        # Nextcloud
        handle_path /nextcloud* {
          reverse_proxy localhost:8081 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        # Paperless
        handle_path /paperless* {
          reverse_proxy localhost:8888 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        # Miniflux
        handle_path /miniflux* {
          reverse_proxy localhost:8086 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
          }
        }

        # Grafana (if monitoring enabled)
        handle_path /grafana* {
          reverse_proxy localhost:3000 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
          }
        }

        # Default handler - homepage dashboard
        handle {
          reverse_proxy localhost:8082
        }
      '';
    };

    # Global settings
    globalConfig = ''
      auto_https off
      admin localhost:2019
      
      log {
        output file /var/log/caddy/access.log {
          roll_size 100mb
          roll_keep 5
        }
        format json
      }
    '';
  };

  # Ensure log directory exists
  systemd.tmpfiles.rules = [
    "d /var/log/caddy 0755 caddy caddy -"
  ];

  # Open firewall ports
  networking.firewall.allowedTCPPorts = [ 80 443 2019 ];
}