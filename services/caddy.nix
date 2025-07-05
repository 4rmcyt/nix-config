
{ config, pkgs, lib, ... }:

{
  services.caddy = {
    enable = true;

    # Use virtualHosts instead of extraConfig for better control
    virtualHosts."localhost" = {
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

        # Miniflux proxy (corrected port)
        handle_path /miniflux* {
          reverse_proxy localhost:8086 {
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

    # Global configuration - simplified and clean
    globalConfig = ''
      {
        auto_https off
        admin localhost:2019
      }
    '';

    # Logging configuration
    logFormat = "json";
  };

  # Ensure log directory exists with proper permissions
  systemd.tmpfiles.rules = [
    "d /var/log/caddy 0755 caddy caddy -"
  ];

  # Open firewall ports for Caddy
  networking.firewall.allowedTCPPorts = [ 80 443 2019 ];

  # Additional Caddy user permissions if needed
  users.users.caddy.extraGroups = [ "caddy" ];
}