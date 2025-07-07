{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.my.caddy-proxy;
in
{
  options.my.caddy-proxy = {
    enable = mkEnableOption "a pre-configured Caddy reverse proxy";

    domain = mkOption {
      type = types.str;
      description = "The domain name to serve traffic for.";
      example = "example.com";
    };

    email = mkOption {
      type = types.str;
      description = "The email address to use for Let's Encrypt SSL certificates.";
      example = "redacted@example.com";
    };
  };

  config = mkIf cfg.enable {

    services.caddy = {
      enable = true;
      email = cfg.email;

      admin = {
        listenAddress = "0.0.0.0:2019";
      };

      package = pkgs.caddy.withPlugins (plugins: [
        plugins.caddy-dns-cloudflare
      ]);

      config = ''
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

    sops.secrets.cloudflare_api_key = {};

    systemd.services.caddy = {
      preStart = ''

        echo "CLOUDFLARE_API_TOKEN=$(cat ${config.sops.secrets.cloudflare_api_key.path})" > /run/caddy-secrets.env
      '';
      serviceConfig = {
        EnvironmentFile = "/run/caddy-secrets.env";
      };
    };
  };
}
