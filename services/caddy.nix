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
    email = "redacted@example.com"; # Email for Let's Encrypt
    user = "caddy";
    group = "caddy";

    # --- CORRECTED: Use the canonical syntax for withPlugins ---
    # This uses a function to select the plugin, which is a more robust
    # way to define the package and resolves the type error.
    package = pkgs.caddy.withPlugins (p: [
      p.caddy-dns-cloudflare
    ]);

    # We provide the entire Caddyfile as a single configuration block.
    config = ''
      # Global options block to configure the admin API.
      {
        admin 0.0.0.0:2019
      }

      # Main site block for your domain.
      example.com {
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

  # --- CORRECTED: Use serviceConfig.Environment ---
  # This directly provides the Cloudflare API token to the Caddy service
  # as an environment variable, which is cleaner than using a preStart script.
  systemd.services.caddy.serviceConfig = {
    Environment = "CLOUDFLARE_API_TOKEN_FILE=${config.sops.secrets.cloudflare_api_key.path}";
  };
}
