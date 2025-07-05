
{ config, pkgs, lib, ... }:

{
  services.caddy = {
    enable = true;

    # Fix: Remove conflicting global config
    globalConfig = '''';

    # Fix: Use proper Caddyfile syntax with global block first
    extraConfig = ''
      {
        # Global options go here first
        auto_https off
        admin localhost:2019

        # Single log configuration
        log {
          output file /var/log/caddy/access.log {
            roll_size 100mb
            roll_keep 5
          }
          format json
        }
      }

      # HTTP server block - only listen on port 80, no service ports
      :80 {
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

        # Audiobookshelf proxy
        handle_path /audiobookshelf* {
          reverse_proxy localhost:8085 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        # Microbin proxy
        handle_path /microbin* {
          reverse_proxy localhost:8083 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
          }
        }

        # Home Assistant proxy
        handle_path /hass* {
          reverse_proxy localhost:8123 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        # Homepage dashboard proxy
        handle_path /homepage* {
          reverse_proxy localhost:8082 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
          }
        }

        # Jellyfin proxy
        handle_path /jellyfin* {
          reverse_proxy localhost:8096 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        # Nextcloud proxy
        handle_path /nextcloud* {
          reverse_proxy localhost:8081 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        # Paperless proxy
        handle_path /paperless* {
          reverse_proxy localhost:8888 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        # Miniflux proxy (port 8086 from media-content.nix)
        handle_path /miniflux* {
          reverse_proxy localhost:8086 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
          }
        }

        # Default handler - redirect to homepage
        handle {
          reverse_proxy localhost:8082
        }
      }
    '';
  };

  # Ensure log directory exists
  systemd.tmpfiles.rules = [
    "d /var/log/caddy 0755 caddy caddy -"
  ];

  # Only open port 80 and 443 for Caddy itself
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}