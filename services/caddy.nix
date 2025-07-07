{ config, pkgs, lib, ... }:

{
  services.caddy = {
    enable = true;
    # Set the ACME email for Let's Encrypt
    email = "4rmcyt@gmail.com";

    # We provide the entire Caddyfile as a single configuration block.
    config = ''
      # Main site block for your domain.
      # Caddy will automatically handle getting a Let's Encrypt certificate.
      labhome.work {
        # Security headers
        header Strict-Transport-Security "max-age=15768000; includeSubDomains"
        header X-Content-Type-Options "nosniff"
        header X-Frame-Options "SAMEORIGIN"
        header Referrer-Policy "strict-origin-when-cross-origin"
        header -Server

        # Compression
        encode gzip zstd

        # Reverse proxy handlers for all your services.
        # We use the simple form of reverse_proxy, letting Caddy handle headers.
        handle /grafana* {
          reverse_proxy localhost:3000
        }

        handle /prometheus* {
          reverse_proxy localhost:9090
        }

        handle /audiobookshelf* {
          reverse_proxy localhost:8085
        }

        handle /microbin* {
          reverse_proxy localhost:8083
        }

        handle /hass* {
          reverse_proxy localhost:8123
        }

        handle /homepage* {
          reverse_proxy localhost:8082
        }

        handle /jellyfin* {
          reverse_proxy localhost:8096
        }

        handle /nextcloud* {
          reverse_proxy localhost:8081
        }

        handle /paperless* {
          reverse_proxy localhost:8888
        }

        handle /miniflux* {
          reverse_proxy localhost:8086
        }

        # Default handler - homepage dashboard
        handle {
          reverse_proxy localhost:8082
        }
      }
    '';
  };
}
