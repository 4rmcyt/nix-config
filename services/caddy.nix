{ config, pkgs, lib, ... }:

{
  services.caddy = {
    enable = true;
    
    # Consider enabling HTTPS in production
    globalConfig = ''
      # Enable auto-HTTPS when moving to production
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
          # Enable HSTS with a 6 month duration
          Strict-Transport-Security "max-age=15768000; includeSubDomains"
          # Prevent MIME type sniffing
          X-Content-Type-Options "nosniff"
          # Clickjacking protection
          X-Frame-Options "SAMEORIGIN"
          # XSS protection
          X-XSS-Protection "1; mode=block"
          # Referrer policy
          Referrer-Policy "strict-origin-when-cross-origin"
          # Remove server identifier
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
          # Nextcloud has special handling requirements
          reverse_proxy localhost:8081 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            # Additional headers for Nextcloud
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

        # Basic rate limiting
        @abuse {
          path_regexp ^/(wp-login|login|admin|xmlrpc)\.php$
          header_regexp User-Agent (curl|wget|python)
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