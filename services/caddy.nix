# /etc/nixos/services/caddy.nix
#
# Configures Caddy as a reverse proxy with automatic HTTPS
# via the Cloudflare DNS challenge.

{ config, lib, pkgs, ... }:

{
  # This file now directly configures the Caddy service,
  # rather than defining a custom module.

  # == Caddy Service Configuration ==
  services.caddy = {
    enable = true;
    email = "4rmcyt@gmail.com"; # Email for Let's Encrypt

    # --- CORRECTED: Use the correct syntax for withPlugins ---
    # We provide a list of plugins directly to the function.
    package = pkgs.caddy.withPlugins [
      pkgs.caddy-dns-cloudflare
    ];

    # We provide the entire Caddyfile as a single configuration block.
    config = ''
      # Global options block to configure the admin API.
      {
        admin 0.0.0.0:2019
      }

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
        handle {
          reverse_proxy localhost:8082
        }
      }
    '';
  };

  # == Systemd and SOPS Integration ==
  # Define the SOPS secret for the Cloudflare API key.
  sops.secrets.cloudflare_api_key = {};

  # Use a systemd pre-start script to create the environment file for Caddy.
  systemd.services.caddy = {
    preStart = ''
      # This script runs before Caddy starts.
      # It reads the API key from the sops-managed secret file and formats it
      # as an environment variable that the Caddy plugin expects.
      echo "CLOUDFLARE_API_TOKEN=$(cat ${config.sops.secrets.cloudflare_api_key.path})" > /run/caddy-secrets.env
    '';
    serviceConfig = {
      # Caddy will load the environment variables from this file.
      EnvironmentFile = "/run/caddy-secrets.env";
    };
  };
}
