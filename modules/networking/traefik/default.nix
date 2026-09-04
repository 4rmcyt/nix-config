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
    sops.secrets.cloudflare_acme_credentials = import ../../../lib/cloudflare-acme-secret.nix "traefik";

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
            forwardedHeaders.trustedIPs = config.my.network.subnets.cloudflare;
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

        # Plugins — local sources, no internet required at startup
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
            # Komga: like security-headers but allow the komf webui to embed
            # Komga (iframe) and call its API cross-origin (CORS with creds).
            komga-headers.headers = {
              browserXssFilter = true;
              contentTypeNosniff = true;
              forceSTSHeader = true;
              stsIncludeSubdomains = true;
              stsPreload = true;
              stsSeconds = 31536000;
              customFrameOptionsValue = "ALLOW-FROM https://komf.${domain}";
              customResponseHeaders."Content-Security-Policy" = "frame-ancestors 'self' https://komf.${domain}";
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
              # Don't block Traefik startup on the first LAPI sync, and never
              # flip the stream to unhealthy on sync failures — otherwise every
              # request gets a blanket 403 for the ~2min CrowdSec takes to come
              # up (hub sync) after a reboot, since Traefik has no ordering
              # dependency on crowdsec.service (see systemd.services.traefik.after
              # below).
              streamStartupBlock = false;
              updateMaxFailure = -1;
              forwardedHeadersTrustedIPs = config.my.network.subnets.cloudflare;
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
              # komf has no authentication, so CORS provides no protection here.
              # Allow any origin so the komf browser extension (moz-extension://…)
              # can reach the API. Credentials must be off when origin is "*".
              accessControlAllowOriginList = ["*"];
              accessControlAllowCredentials = false;
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
            lazylibrarian = {
              rule = "Host(`lazylibrarian.${domain}`)";
              entryPoints = ["websecure"];
              service = "lazylibrarian";
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
            seerr = {
              rule = "Host(`seerr.${domain}`)";
              entryPoints = ["websecure"];
              service = "seerr";
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
            komga = {
              rule = "Host(`komga.${domain}`)";
              entryPoints = ["websecure"];
              service = "komga";
              middlewares = [
                "komga-headers"
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
            dispatcharr = {
              rule = "Host(`dispatcharr.${domain}`)";
              entryPoints = ["websecure"];
              service = "dispatcharr";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            radicale = {
              rule = "Host(`cal.${domain}`)";
              entryPoints = ["websecure"];
              service = "radicale";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            ntfy = {
              rule = "Host(`ntfy.${domain}`)";
              entryPoints = ["websecure"];
              service = "ntfy";
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };

            # job-kombayn: API on /api (higher priority = more specific path
            # wins over the SPA catch-all below), everything else -> static SPA.
            kombayn-api = {
              rule = "Host(`jobko.${domain}`) && PathPrefix(`/api`)";
              entryPoints = ["websecure"];
              service = "kombayn-api";
              priority = 10;
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
            kombayn-web = {
              rule = "Host(`jobko.${domain}`)";
              entryPoints = ["websecure"];
              service = "kombayn-web";
              priority = 1;
              middlewares = [
                "security-headers"
                "crowdsec"
              ];
              tls.certResolver = "default";
            };
          };

          services = {
            # Nixarr
            sonarr.loadBalancer.servers = [{url = "http://localhost:${toString config.my.network.ports.sonarr}";}];
            radarr.loadBalancer.servers = [{url = "http://localhost:${toString config.my.network.ports.radarr}";}];
            prowlarr.loadBalancer.servers = [{url = "http://localhost:${toString config.my.network.ports.prowlarr}";}];
            bazarr.loadBalancer.servers = [{url = "http://localhost:${toString config.my.network.ports.bazarr}";}];
            lidarr.loadBalancer.servers = [{url = "http://localhost:${toString config.my.network.ports.lidarr}";}];
            lazylibrarian.loadBalancer.servers = [{url = "http://localhost:${toString config.my.network.ports.lazylibrarian}";}];
            kapowarr.loadBalancer.servers = [{url = "http://localhost:5656";}];
            seerr.loadBalancer.servers = [{url = "http://localhost:5055";}];

            # Media
            jellyfin.loadBalancer.servers = [{url = "http://localhost:${toString config.my.network.ports.jellyfin}";}];
            qb.loadBalancer.servers = [{url = "http://localhost:8081";}];
            komf.loadBalancer.servers = [{url = "http://localhost:8085";}];
            komga.loadBalancer.servers = [{url = "http://localhost:8087";}];

            # Monitoring
            grafana.loadBalancer.servers = [{url = "http://localhost:${toString config.my.network.ports.grafana}";}];

            # Reading
            miniflux.loadBalancer.servers = [{url = "http://localhost:${toString config.my.network.ports.miniflux}";}];
            audiobookshelf.loadBalancer.servers = [{url = "http://localhost:${toString config.my.network.ports.audiobookshelf}";}];

            # Smart home
            hass.loadBalancer.servers = [{url = "http://localhost:${toString config.my.network.ports.home-assistant}";}];

            # Productivity
            homepage.loadBalancer.servers = [{url = "http://localhost:${toString config.my.network.ports.homepage}";}];
            microbin.loadBalancer.servers = [{url = "http://localhost:8069";}];
            atuin.loadBalancer.servers = [{url = "http://localhost:8881";}];
            livesync.loadBalancer.servers = [{url = "http://localhost:5984";}];
            dispatcharr.loadBalancer.servers = [{url = "http://localhost:9191";}];
            radicale.loadBalancer.servers = [{url = "http://localhost:${toString config.my.network.ports.radicale}";}];
            ntfy.loadBalancer.servers = [{url = "http://localhost:9991";}];

            # job-kombayn
            kombayn-api.loadBalancer.servers = [{url = "http://localhost:8420";}];
            kombayn-web.loadBalancer.servers = [{url = "http://localhost:8421";}];
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

    # CrowdSec bouncer runs in stream mode and caches decisions locally —
    # Traefik does not need to wait for it. crowdsec-setup takes ~2min on
    # boot (hub sync) which caused Traefik to delay that long.
    systemd.services.traefik.after = ["network-online.target" "sops-nix.service"];
    systemd.services.traefik.wants = ["network-online.target"];
  };
}
