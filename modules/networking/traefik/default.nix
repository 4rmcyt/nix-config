{
  config,
  lib,
  ...
}: let
  cfg = config.my.traefik;
  inherit (config.my.defaults) domain;
in {
  options.my.traefik = {
    enable = lib.mkEnableOption "Traefik reverse proxy";
  };

  config = lib.mkIf cfg.enable {
    # Cloudflare DNS-01 credentials — Traefik reads as EnvironmentFile
    sops.secrets.cloudflare_acme_credentials = {
      sopsFile = ../../../secrets/cloudflare_acme_credentials.env;
      owner = "traefik";
      group = "traefik";
      mode = "0400";
      format = "dotenv";
    };

    users.users.traefik = {
      isSystemUser = true;
      group = "traefik";
    };
    users.groups.traefik = {};

    services.traefik = {
      enable = true;

      staticConfigOptions = {
        entryPoints = {
          web = {
            address = ":80";
            http.redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
            };
          };
          websecure = {
            address = ":443";
            http.tls = {
              certResolver = "default";
              domains = [
                {
                  main = domain;
                  sans = ["*.${domain}"];
                }
              ];
            };
            # Trust Cloudflare's IPs so CF-Connecting-IP / X-Forwarded-For
            # carries the real client IP (needed for fail2ban on hass).
            forwardedHeaders.trustedIPs = [
              "173.245.48.0/20"
              "103.21.244.0/22"
              "103.22.200.0/22"
              "103.31.4.0/22"
              "141.101.64.0/18"
              "108.162.192.0/18"
              "190.93.240.0/20"
              "188.114.96.0/20"
              "197.234.240.0/22"
              "198.41.128.0/17"
              "162.158.0.0/15"
              "104.16.0.0/13"
              "104.24.0.0/14"
              "172.64.0.0/13"
              "131.0.72.0/22"
            ];
          };
        };

        api = {
          dashboard = true;
          insecure = false;
        };

        certificatesResolvers.default.acme = {
          inherit (config.my.defaults) email;
          storage = "/var/lib/traefik/acme.json";
          dnsChallenge = {
            provider = "cloudflare";
            resolvers = [
              "1.1.1.1:53"
              "8.8.8.8:53"
            ];
          };
        };

        log = {
          level = "INFO";
          filePath = "/var/log/traefik/traefik.log";
        };

        accessLog = {
          filePath = "/var/log/traefik/access.log";
          format = "json";
          bufferingSize = 100;
          filters = {
            statusCodes = ["400-599"];
            retryAttempts = true;
            minDuration = "1s";
          };
        };

        metrics.prometheus = {
          addEntryPointsLabels = true;
          addRoutersLabels = true;
          addServicesLabels = true;
          entryPoint = "metrics";
        };

        entryPoints.metrics.address = "127.0.0.1:8080";

        # Localhost-only entrypoint for the API (used by homepage widget)
        entryPoints.traefik-api.address = "127.0.0.1:8083";

        # ----------------------------------------------------------------
        # Plugins — local sources, no internet required at startup
        # ----------------------------------------------------------------
        experimental.localPlugins = {
          bouncer = {
            moduleName = "github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin";
          };
          geoblock = {
            moduleName = "github.com/david-garcia-garcia/traefik-geoblock";
            settings.useunsafe = true;
          };
        };
      };

      # NixOS writes this to a file and wires the file provider automatically
      dynamicConfigOptions = {
        http = {
          middlewares = {
            security-headers.headers = {
              frameDeny = true;
              browserXssFilter = true;
              contentTypeNosniff = true;
              forceSTSHeader = true;
              stsIncludeSubdomains = true;
              stsPreload = true;
              stsSeconds = 31536000;
              customFrameOptionsValue = "SAMEORIGIN";
            };
            # Rate limiter for public-facing services (hass)
            rate-limit.rateLimit = {
              average = 100;
              burst = 50;
            };
            # CrowdSec bouncer — applied to all routers
            crowdsec.plugin.bouncer = {
              enabled = true;
              crowdsecMode = "stream";
              crowdsecLapiKeyFile = config.sops.secrets.crowdsec_bouncer_key.path;
              crowdsecLapiHost = "127.0.0.1:8088";
              crowdsecLapiScheme = "http";
              updateIntervalSeconds = 60;
              forwardedHeadersTrustedIPs = [
                "173.245.48.0/20"
                "103.21.244.0/22"
                "103.22.200.0/22"
                "103.31.4.0/22"
                "141.101.64.0/18"
                "108.162.192.0/18"
                "190.93.240.0/20"
                "188.114.96.0/20"
                "197.234.240.0/22"
                "198.41.128.0/17"
                "162.158.0.0/15"
                "104.16.0.0/13"
                "104.24.0.0/14"
                "172.64.0.0/13"
                "131.0.72.0/22"
              ];
            };
            # Geoblock — Canada only, for public-facing hass
            geoblock.plugin.geoblock = {
              enabled = true;
              defaultAllow = false;
              allowPrivate = true;
              # DB is bundled with the plugin source in the Nix store
              databaseFilePath = "/var/lib/traefik/plugins-local/src/github.com/david-garcia-garcia/traefik-geoblock/IP2LOCATION-LITE-DB1.IPV6.BIN";
              databaseAutoUpdate = true;
              databaseAutoUpdateDir = "/var/lib/traefik/geoblock";
              allowedCountries = [
                "CA"
                "US"
              ];
              allowedIPBlocks = [
                "100.64.0.0/10"
                "192.168.1.0/24"
              ]; # Tailscale CGNAT + LAN
              ipHeaders = [
                "x-forwarded-for"
                "x-real-ip"
              ];
              disallowedStatusCode = 403;
            };
            komf-headers.headers = {
              accessControlAllowMethods = [
                "GET"
                "POST"
                "PUT"
                "DELETE"
                "OPTIONS"
                "PATCH"
              ];
              accessControlAllowHeaders = ["*"];
              accessControlAllowOriginList = ["https://komf.${domain}"];
              accessControlAllowCredentials = true;
              accessControlMaxAge = 100;
              addVaryHeader = true;
            };
          };

          routers = {
            traefik-dashboard = {
              rule = "Host(`traefik.${domain}`)";
              entryPoints = ["websecure"];
              service = "api@internal";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };

            # Internal API router for homepage widget (localhost only, no middleware)
            traefik-api-internal = {
              rule = "PathPrefix(`/`)";
              entryPoints = ["traefik-api"];
              service = "api@internal";
              middlewares = [];
            };

            slskd = {
              rule = "Host(`slskd.${domain}`)";
              entryPoints = ["websecure"];
              service = "slskd";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };

            # Nixarr
            sonarr = {
              rule = "Host(`sonarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "sonarr";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            radarr = {
              rule = "Host(`radarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "radarr";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            prowlarr = {
              rule = "Host(`prowlarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "prowlarr";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            bazarr = {
              rule = "Host(`bazarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "bazarr";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            lidarr = {
              rule = "Host(`lidarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "lidarr";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            readarr = {
              rule = "Host(`readarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "readarr";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };

            kapowarr = {
              rule = "Host(`kapowarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "kapowarr";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            jellyseerr = {
              rule = "Host(`jellyseerr.${domain}`)";
              entryPoints = ["websecure"];
              service = "jellyseerr";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };

            # Media
            jellyfin = {
              rule = "Host(`jellyfin.${domain}`)";
              entryPoints = ["websecure"];
              service = "jellyfin";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            qb = {
              rule = "Host(`qb.${domain}`)";
              entryPoints = ["websecure"];
              service = "qb";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            tdarr = {
              rule = "Host(`tdarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "tdarr";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };

            # Monitoring
            grafana = {
              rule = "Host(`grafana.${domain}`)";
              entryPoints = ["websecure"];
              service = "grafana";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };

            # Reading
            miniflux = {
              rule = "Host(`miniflux.${domain}`)";
              entryPoints = ["websecure"];
              service = "miniflux";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            kavita = {
              rule = "Host(`kavita.${domain}`)";
              entryPoints = ["websecure"];
              service = "kavita";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            komga = {
              rule = "Host(`komga.${domain}`)";
              entryPoints = ["websecure"];
              service = "komga";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            komf = {
              rule = "Host(`komf.${domain}`)";
              entryPoints = ["websecure"];
              service = "komf";
              middlewares = [
                "komf-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            audiobookshelf = {
              rule = "Host(`audiobookshelf.${domain}`)";
              entryPoints = ["websecure"];
              service = "audiobookshelf";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };

            # Smart home
            hass = {
              rule = "Host(`hass.${domain}`)";
              entryPoints = ["websecure"];
              service = "hass";
              middlewares = [
                "security-headers"
                "rate-limit"
                "crowdsec"
                "geoblock"
              ];
              tls.certResolver = "default";
            };

            # Productivity
            homepage = {
              rule = "Host(`home.${domain}`)";
              entryPoints = ["websecure"];
              service = "homepage";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            microbin = {
              rule = "Host(`microbin.${domain}`)";
              entryPoints = ["websecure"];
              service = "microbin";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            vaultwarden = {
              rule = "Host(`vault.${domain}`)";
              entryPoints = ["websecure"];
              service = "vaultwarden";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            atuin = {
              rule = "Host(`atuin.${domain}`)";
              entryPoints = ["websecure"];
              service = "atuin";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            livesync = {
              rule = "Host(`livesync.${domain}`)";
              entryPoints = ["websecure"];
              service = "livesync";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            calibre-web = {
              rule = "Host(`calibre.${domain}`)";
              entryPoints = ["websecure"];
              service = "calibre-web";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
          };

          services = {
            slskd.loadBalancer.servers = [{url = "http://localhost:5030";}];

            # Nixarr
            sonarr.loadBalancer.servers = [{url = "http://localhost:8990";}];
            radarr.loadBalancer.servers = [{url = "http://localhost:7878";}];
            prowlarr.loadBalancer.servers = [{url = "http://localhost:9696";}];
            bazarr.loadBalancer.servers = [{url = "http://localhost:6767";}];
            lidarr.loadBalancer.servers = [{url = "http://localhost:8686";}];
            readarr.loadBalancer.servers = [{url = "http://localhost:8787";}];
            kapowarr.loadBalancer.servers = [{url = "http://localhost:5656";}];
            jellyseerr.loadBalancer.servers = [{url = "http://localhost:5055";}];

            # Media
            jellyfin.loadBalancer.servers = [{url = "http://localhost:8096";}];
            qb.loadBalancer.servers = [{url = "http://localhost:8081";}];
            tdarr.loadBalancer.servers = [{url = "http://localhost:8265";}];
            calibre-web.loadBalancer.servers = [{url = "http://localhost:8084";}];
            komf.loadBalancer.servers = [{url = "http://localhost:8085";}];
            komga.loadBalancer.servers = [{url = "http://localhost:8087";}];

            # Monitoring
            grafana.loadBalancer.servers = [{url = "http://localhost:3003";}];

            # Reading
            miniflux.loadBalancer.servers = [{url = "http://localhost:8086";}];
            kavita.loadBalancer.servers = [{url = "http://localhost:5000";}];
            audiobookshelf.loadBalancer.servers = [{url = "http://localhost:9292";}];

            # Smart home
            hass.loadBalancer.servers = [{url = "http://localhost:8123";}];

            # Productivity
            homepage.loadBalancer.servers = [{url = "http://localhost:8082";}];
            microbin.loadBalancer.servers = [{url = "http://localhost:8069";}];
            vaultwarden.loadBalancer.servers = [{url = "http://localhost:8222";}];
            atuin.loadBalancer.servers = [{url = "http://localhost:8881";}];
            livesync.loadBalancer.servers = [{url = "http://localhost:5984";}];
          };
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/traefik 0755 traefik traefik -"
      "d /var/log/traefik 0755 traefik traefik -"
    ];

    services.logrotate.settings.traefik = {
      files = "/var/log/traefik/*.log";
      frequency = "daily";
      rotate = 14;
      compress = true;
      delaycompress = true;
      missingok = true;
      notifempty = true;
      postrotate = "systemctl kill --kill-who=main --signal=USR1 traefik.service";
    };

    # Cloudflare credentials injected as environment variables
    systemd.services.traefik.serviceConfig.EnvironmentFile =
      config.sops.secrets.cloudflare_acme_credentials.path;
  };
}
