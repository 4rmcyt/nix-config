# /etc/nixos/services/caddy.nix
#
# Configures Caddy as a reverse proxy with automatic HTTPS
# via the Cloudflare DNS challenge, following modern best practices.

{ config, lib, pkgs, ... }:

{
  # == Caddy Service Configuration ==
  services.caddy = {
    enable = true;
    email = "4rmcyt@gmail.com"; # Email for Let's Encrypt
    user = "caddy";
    group = "caddy";

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
        # ACME challenge. The plugin will read the token from the
        # CLOUDFLARE_API_TOKEN_FILE environment variable.
        tls {
          dns cloudflare
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

  # == Systemd and SOPS Integration (Following noah.masu.rs example) ==

  # This defines a secret for the Cloudflare API token.
  # sops-nix will look for a key named 'cloudflare_api_key' in your default secrets.yaml file.
  sops.secrets.cloudflare_api_key = {};

  # This directly provides the path to the decrypted secret file to the Caddy service
  # as an environment variable. This is the cleanest way to handle this.
  systemd.services.caddy.serviceConfig = {
    # The Environment option expects a list of strings.
    Environment = [
      "CLOUDFLARE_API_TOKEN_FILE=${config.sops.secrets.cloudflare_api_key.path}"
    ];
  };
}
