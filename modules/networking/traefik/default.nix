{
  config,
  lib,
  ...
}: let
  cfg = config.my.traefik;
  inherit (config.my.defaults) domain;

  # Declarative table for the common case: one router + one service per
  # backend, proxied to a localhost port behind the standard security
  # middlewares. Anything with non-standard routing (path-based rules,
  # priority, internal-only entrypoints) is defined by hand instead —
  # see traefik-dashboard/traefik-api-internal/kombayn-* below.
  mkProxiedRouter = name: {
    port,
    middlewares ? ["security-headers" "crowdsec"],
    host ? "${name}.${domain}",
  }: {
    routers.${name} = {
      rule = "Host(`${host}`)";
      entryPoints = ["websecure"];
      service = name;
      inherit middlewares;
      tls.certResolver = "default";
    };
    services.${name}.loadBalancer.servers = [{url = "http://localhost:${toString port}";}];
  };

  proxiedServices = {
    # Nixarr
    sonarr.port = config.my.network.ports.sonarr;
    radarr.port = config.my.network.ports.radarr;
    prowlarr.port = config.my.network.ports.prowlarr;
    bazarr.port = config.my.network.ports.bazarr;
    lidarr.port = config.my.network.ports.lidarr;
    lazylibrarian.port = config.my.network.ports.lazylibrarian;
    kapowarr.port = config.my.network.ports.kapowarr;
    seerr.port = config.my.network.ports.seerr;

    # Media
    jellyfin.port = config.my.network.ports.jellyfin;
    qb.port = config.my.network.ports.qb;

    # Monitoring
    grafana.port = config.my.network.ports.grafana;

    # Reading
    miniflux.port = config.my.network.ports.miniflux;
    komga = {
      port = config.my.network.ports.komga;
      middlewares = ["komga-headers" "crowdsec"];
    };
    komf = {
      port = config.my.network.ports.komf;
      middlewares = ["komf-headers" "crowdsec"];
    };
    audiobookshelf.port = config.my.network.ports.audiobookshelf;

    # Smart home
    hass = {
      port = config.my.network.ports.home-assistant;
      middlewares = ["security-headers" "rate-limit" "crowdsec" "geoblock"];
    };

    # Productivity
    homepage = {
      port = config.my.network.ports.homepage;
      host = "home.${domain}";
    };
    microbin.port = config.my.network.ports.microbin;
    atuin.port = config.services.atuin.port;
    livesync.port = config.services.couchdb.port;
    dispatcharr.port = config.my.network.ports.dispatcharr;
    radicale = {
      port = config.my.network.ports.radicale;
      host = "cal.${domain}";
    };
    ntfy.port = config.my.network.ports.ntfy;
  };

  generatedRoutes = lib.foldl' lib.recursiveUpdate {} (lib.mapAttrsToList mkProxiedRouter proxiedServices);
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

        entryPoints.metrics.address = "127.0.0.1:${toString config.my.network.ports.traefik-metrics}";

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
                config.my.network.subnets.tailscale
                config.my.network.subnets.trusted
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

          routers =
            generatedRoutes.routers
            // {
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

          services =
            generatedRoutes.services
            // {
              # job-kombayn
              kombayn-api.loadBalancer.servers = [{url = "http://localhost:${toString config.services.jobKombayn.apiPort}";}];
              kombayn-web.loadBalancer.servers = [{url = "http://localhost:${toString config.services.jobKombayn.webPort}";}];
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
