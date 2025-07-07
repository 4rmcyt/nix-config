# /etc/nixos/services/caddy.nix
#
# A self-contained module to configure Caddy as a reverse proxy
# with automatic HTTPS via the Cloudflare DNS challenge.

{ config, lib, pkgs, ... }:

with lib;

let
  # 'cfg' refers to OUR module's options, under the unique name "my.caddy-proxy"
  cfg = config.my.caddy-proxy;
in
{
  # == 1. Define the options for THIS module ==
  options.my.caddy-proxy = {
    enable = mkEnableOption "a pre-configured Caddy reverse proxy";

    domain = mkOption {
      type = types.str;
      description = "The domain name to serve traffic for.";
      example = "labhome.work";
    };

    email = mkOption {
      type = types.str;
      description = "The email address to use for Let's Encrypt SSL certificates.";
      example = "4rmcyt@gmail.com";
    };
  };

  # == 2. Configure the system if our module is enabled ==
  config = mkIf cfg.enable {

    # == Caddy Service Configuration ==
    services.caddy = {
      enable = true;
      email = cfg.email;

      # Use Caddy with the Cloudflare DNS plugin
      package = pkgs.caddy.withPlugins (plugins: [
        plugins.caddy-dns-cloudflare
      ]);

      # We provide the entire Caddyfile as a single configuration block.
      config = ''
        # --- CORRECTED: Global options block ---
        # This configures global settings for Caddy, including the admin API.
        {
          # Make the admin API accessible on the local network at http://<ip>:2019
          admin 0.0.0.0:2019
        }

        # Main site block for your domain.
        ${cfg.domain} {
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
  };
}
