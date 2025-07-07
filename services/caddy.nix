{ config, pkgs, lib, ... }:

{
  services.caddy = {
    enable = true;
    # Set the ACME email for Let's Encrypt
    email = "redacted@example.com";

    # --- CORRECTED ---
    # The global options block is moved here, to the top level of the Caddyfile.
    # This resolves the syntax error.
    globalConfig = ''
      {
        # This disables the local CA to prevent log errors, as we are using a public CA (Let's Encrypt).
        local_certs
      }
    '';

    # Change the host from an IP to the domain name.
    # Caddy will automatically provision a Let's Encrypt certificate for this domain.
    virtualHosts."example.com" = {
      extraConfig = ''
        # Security headers
        header Strict-Transport-Security "max-age=15768000; includeSubDomains"
        header X-Content-Type-Options "nosniff"
        header X-Frame-Options "SAMEORIGIN"
        header Referrer-Policy "strict-origin-when-cross-origin"
        header -Server

        # Compression
        encode gzip zstd

        # By removing the manual `header_up` directives, we let Caddy use its
        # smart defaults. This automatically handles all the necessary headers
        # and resolves the "Unnecessary header_up" warnings.

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
      '';
    };
  };

  # REMOVED: Firewall ports (now handled centrally in networking.nix)
}
