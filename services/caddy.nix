{ config, pkgs, lib, ... }:

{
  services.caddy = {
    enable = true;

    virtualHosts."192.168.1.165" = {
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

        # Netdata - Real-time monitoring
        handle /netdata* {
          reverse_proxy localhost:19999 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        # Grafana - Special handling for subpath
        handle /grafana* {
          reverse_proxy localhost:3000 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
            header_up X-Forwarded-Host {host}
          }
        }

        # Prometheus - Metrics server
        handle /prometheus* {
          reverse_proxy localhost:9090 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
          }
        }

        # Audiobookshelf
        handle /audiobookshelf* {
          reverse_proxy localhost:8085 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        # Microbin
        handle /microbin* {
          reverse_proxy localhost:8083 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
          }
        }

        # Home Assistant
        handle /hass* {
          reverse_proxy localhost:8123 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-For {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        # Homepage dashboard
        handle /homepage* {
          reverse_proxy localhost:8082 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
          }
        }

        # Jellyfin
        handle /jellyfin* {
          reverse_proxy localhost:8096 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        # Nextcloud
        handle /nextcloud* {
          reverse_proxy localhost:8081 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        # Paperless
        handle /paperless* {
          reverse_proxy localhost:8888 {
            header_up Host {upstream_hostport}
            header_up X-Real-IP {remote_host}
            header_up X-Forwarded-Proto {scheme}
          }
        }

        # Miniflux
        handle /miniflux* {
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
  };

  # Open firewall ports
  networking.firewall.allowedTCPPorts = [ 80 443 2019 ];
}