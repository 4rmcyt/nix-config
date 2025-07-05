
{ config, pkgs, lib, ... }:

{
  services.caddy = {
    enable = true;

    globalConfig = ''
      auto_https off

      log {
        output file /var/log/caddy/access.log
        format json
      }
    '';

    extraConfig = ''
      :80, :443 {
        header {
          Strict-Transport-Security "max-age=15768000; includeSubDomains"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "SAMEORIGIN"
          X-XSS-Protection "1; mode=block"
          Referrer-Policy "strict-origin-when-cross-origin"
          -Server
        }

        encode gzip zstd

        handle_path /audiobookshelf* {
          reverse_proxy localhost:8085 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        handle_path /microbin* {
          reverse_proxy localhost:8083 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
          }
        }

        handle_path /hass* {
          reverse_proxy localhost:8123 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
          }
        }

        handle_path /homepage* {
          reverse_proxy localhost:8082 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
          }
        }

        handle_path /jellyfin* {
          reverse_proxy localhost:8096 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
          }
        }

        handle_path /nextcloud* {
          reverse_proxy localhost:8081 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        handle_path /paperless* {
          reverse_proxy localhost:8888 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        handle {
          reverse_proxy localhost:8082
        }

        @abuse path_regexp ^/(wp-login|admin)\.php$
        handle @abuse {
          respond "Access denied" 403
        }
      }
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/log/caddy 0755 caddy caddy -"
  ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}