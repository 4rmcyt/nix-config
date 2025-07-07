{ config, pkgs, lib, ... }:

{
  # == 1. Caddy Service Configuration ==
  services.caddy = {
    enable = true;
    # Set the ACME email for Let's Encrypt
    email = "4rmcyt@gmail.com";

    # Use Caddy with the Cloudflare DNS plugin
    package = pkgs.caddy.withPlugins (plugins: [
      plugins.caddy-dns-cloudflare
    ]);

    # We provide the entire Caddyfile as a single configuration block.
    config = ''
      # Main site block for your domain.
      labhome.work {
        # This tells Caddy to use the Cloudflare DNS provider to solve the
        # ACME challenge, reading the token from the environment variable.
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }

        # Security headers
        header Strict-Transport-Security "max-age=15768000; includeSubDomains"
        header X-Content-Type-Options "nosniff"
        header X-Frame-Options "SAMEORIGIN"
        header Referrer-Policy "strict-origin-when-cross-origin"
        header -Server

        # Compression
        encode gzip zstd

        # Reverse proxy handlers for all your services.
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

 
  sops.secrets.cloudflare_api_key = {};

  systemd.services.caddy = {
    preStart = ''
      echo "CLOUDFLARE_API_TOKEN=$(cat ${config.sops.secrets.cloudflare_api_key.path})" > /run/caddy-secrets.env
    '';
    serviceConfig = {
      EnvironmentFile = "/run/caddy-secrets.env";
    };
  };
}
