
{ config, pkgs, lib, ... }:

{
  services.caddy = {
    enable = true;

    globalConfig = ''
      # Disable auto-HTTPS for local development
      auto_https off

      # Log settings
      log {
        output file /var/log/caddy/access.log
        format json
      }
    '';

    extraConfig = ''
      :80, :443 {
        # Common security headers for all routes
        header {
          Strict-Transport-Security "max-age=15768000; includeSubDomains"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "SAMEORIGIN"
          X-XSS-Protection "1; mode=block"
          Referrer-Policy "strict-origin-when-cross-origin"
          -Server
        }

        # Enable compression
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
          }
        }

        # Homepage
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

        # Default to homepage
        handle {
          reverse_proxy localhost:8082
        }

        # Basic rate limiting for known attack patterns
        @abuse {
          path_regexp ^/(wp-login|login|admin|xmlrpc)\.php$
        }
        handle @abuse {
          respond "Access denied" 403
        }
      }
    '';
  };

  # Create log directory
  systemd.tmpfiles.rules = [
    "d /var/log/caddy 0755 caddy caddy -"
  ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}