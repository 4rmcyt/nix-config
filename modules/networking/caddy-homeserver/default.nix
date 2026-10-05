{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.my.caddyHomeserver;
  inherit (config.my.defaults) domain email;
  inherit (config.my.network) ports subnets;

  # Downloaded monthly by modules/monitoring/geoip.nix (db-ip lite, MaxMind MMDB format).
  geoipDb = "/var/lib/geoip/city.mmdb";
  # Tailscale CGNAT isn't in Caddy's private_ranges shortcut.
  lanRanges = "private_ranges ${subnets.tailscale} ${subnets.trusted}";

  # Journal so CrowdSec (my.crowdsec.caddy) and Alloy pick it up.
  journalLog = ''
    output stderr
    format json
  '';

  sts = ''Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"'';
  corsMethods = ''Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS, PATCH"'';

  headerSets = {
    security = ''
      header {
        # Apply after reverse_proxy so we replace upstream's copies instead of duplicating them.
        defer
        ${sts}
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
        X-XSS-Protection "1; mode=block"
      }
    '';
    # Allows the komf webui to embed Komga (iframe) and call its API cross-origin.
    komga = ''
      header {
        defer
        ${sts}
        X-Content-Type-Options "nosniff"
        X-XSS-Protection "1; mode=block"
        X-Frame-Options "ALLOW-FROM https://komf.${domain}"
        Content-Security-Policy "frame-ancestors 'self' https://komf.${domain}"
        Access-Control-Allow-Origin "https://komf.${domain}"
        Access-Control-Allow-Credentials "true"
        ${corsMethods}
        Access-Control-Allow-Headers "*"
        Access-Control-Max-Age "100"
        +Vary "Origin"
      }
      @preflight {
        method OPTIONS
        header Origin https://komf.${domain}
        header Access-Control-Request-Method *
      }
      respond @preflight 204
    '';
    # komf has no auth, so CORS provides no real protection; wildcard lets the browser extension in.
    komf = ''
      header {
        defer
        Access-Control-Allow-Origin "*"
        ${corsMethods}
        Access-Control-Allow-Headers "*"
        Access-Control-Max-Age "100"
        +Vary "Origin"
      }
      @preflight {
        method OPTIONS
        header Access-Control-Request-Method *
      }
      respond @preflight 204
    '';
  };

  geoblock = ''
    @geoblocked {
      not client_ip ${lanRanges}
      not {
        maxmind_geolocation {
          db_path ${geoipDb}
          allow_countries CA US
        }
      }
    }
    respond @geoblocked 403
  '';

  # Sliding-window approximation of Traefik's average=100/burst=50.
  rateLimit = name: ''
    rate_limit {
      zone ${name} {
        key {client_ip}
        events 100
        window 1s
      }
    }
  '';

  lanOnly = ''
    @external not client_ip ${lanRanges}
    respond @external 403
  '';

  proxyTo = {
    port,
    scheme ? "http",
    insecureTls ? false,
  }:
    if insecureTls
    then ''
      reverse_proxy ${scheme}://localhost:${toString port} {
        transport http {
          tls_insecure_skip_verify
        }
      }
    ''
    else "reverse_proxy ${scheme}://localhost:${toString port}";

  mkSite = name: {
    port ? null,
    host ? "${name}.${domain}",
    headers ? "security",
    scheme ? "http",
    insecureTls ? false,
    geo ? false,
    limit ? false,
    lan ? false,
    waf ? false,
    compress ? true,
    body ? proxyTo {inherit port scheme insecureTls;},
  }:
    lib.nameValuePair host {
      logFormat = journalLog;
      extraConfig = ''
        route {
          crowdsec
          ${lib.optionalString waf "appsec"}
          ${lib.optionalString lan lanOnly}
          ${lib.optionalString geo geoblock}
          ${lib.optionalString limit (rateLimit name)}
          ${headerSets.${headers}}
          ${lib.optionalString compress "encode zstd gzip"}
          ${body}
        }
      '';
    };

  sites = {
    sonarr.port = ports.sonarr;
    radarr.port = ports.radarr;
    prowlarr.port = ports.prowlarr;
    bazarr.port = ports.bazarr;
    lidarr.port = ports.lidarr;
    lazylibrarian.port = ports.lazylibrarian;
    kapowarr.port = ports.kapowarr;
    seerr.port = ports.seerr;

    jellyfin.port = ports.jellyfin;
    qb.port = ports.qb;

    grafana.port = ports.grafana;

    miniflux.port = ports.miniflux;
    komga = {
      port = ports.komga;
      headers = "komga";
    };
    komf = {
      port = ports.komf;
      headers = "komf";
    };
    audiobookshelf.port = ports.audiobookshelf;

    # waf = true on the Cloudflare Tunnel hostnames (modules/networking/cloudflared).
    hass = {
      port = ports.home-assistant;
      geo = true;
      limit = true;
      waf = true;
    };

    homepage = {
      port = ports.homepage;
      host = "home.${domain}";
    };
    microbin.port = ports.microbin;
    atuin.port = config.services.atuin.port;
    livesync = {
      port = config.services.couchdb.port;
      waf = true;
    };
    radicale = {
      port = ports.radicale;
      host = "cal.${domain}";
      waf = true;
    };
    ntfy = {
      port = ports.ntfy;
      waf = true;
      # Streams JSON/SSE subscriptions; keep them unbuffered.
      compress = false;
    };
    local-registry = {
      port = ports.local-registry;
      host = "registry.${domain}";
    };

    # Self-signed TLS internally (see modules/security/kanidm).
    kanidm = {
      host = "idm.${domain}";
      waf = true;
      body = ''
        reverse_proxy https://${config.services.kanidm.server.settings.bindaddress} {
          transport http {
            tls_insecure_skip_verify
          }
        }
      '';
    };

    jobko = {
      waf = true;
      body = ''
        handle /api* {
          reverse_proxy localhost:${toString config.services.jobKombayn.apiPort}
        }
        handle {
          reverse_proxy localhost:${toString config.services.jobKombayn.webPort}
        }
      '';
    };

    # k3s NodePort (modules/services/argocd/server-nodeport.yaml); argocd-server runs TLS, not --insecure.
    argocd = {
      port = 30080;
      scheme = "https";
      insecureTls = true;
      lan = true;
    };
  };

  # Only these sites exist on the guest port, so headscale's guest@ grant can't reach the rest.
  guestSites = ["jellyfin" "audiobookshelf" "komga" "seerr"];
  guestVirtualHosts = lib.mapAttrs' (name: site: let
    s = mkSite name site;
  in
    lib.nameValuePair "${s.name}:${toString ports.caddy-guest}" s.value) (lib.getAttrs guestSites sites);
in {
  options.my.caddyHomeserver = {
    enable = lib.mkEnableOption "Caddy reverse proxy for homeserver (Traefik replacement)";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.my.traefik.enable;
        message = "my.caddyHomeserver and my.traefik both bind :80/:443 and share the CrowdSec bouncer key.";
      }
    ];

    sops.secrets.cloudflare_acme_credentials = import ../../../lib/cloudflare-acme-secret.nix "caddy";
    sops.secrets.crowdsec_bouncer_key.sopsFile = ../../../secrets/crowdsec.yaml;
    sops.templates."caddy-crowdsec.env" = {
      content = "CROWDSEC_API_KEY=${config.sops.placeholder.crowdsec_bouncer_key}\n";
      owner = "caddy";
      # Env is read at process start; reload wouldn't pick up a rotated key.
      restartUnits = ["caddy.service"];
    };

    services.caddy = {
      enable = true;
      package = import ../../../lib/caddy-with-plugins.nix pkgs "homeserver";

      globalConfig = ''
        email ${email}
        # Below the unit's TimeoutStopSec=5s; eternal default left websockets open until SIGKILL.
        grace_period 3s
        admin localhost:${toString ports.caddy-admin}
        metrics {
          per_host
        }
        acme_dns cloudflare {env.CLOUDFLARE_DNS_API_TOKEN}
        tls_resolvers 1.1.1.1 8.8.8.8

        crowdsec {
          api_url http://127.0.0.1:${toString ports.crowdsec-lapi}
          api_key {$CROWDSEC_API_KEY}
          ticker_interval 60s
          appsec_url http://127.0.0.1:${toString ports.crowdsec-appsec}
          # Availability over blocking while crowdsec.service restarts / hub-syncs after boot.
          appsec_fail_open
        }

        servers {
          # Cloudflare edge plus cloudflared on loopback (tunnel origin is https://localhost:443).
          trusted_proxies static ${lib.concatStringsSep " " subnets.cloudflare} 127.0.0.1/32 ::1/128
          client_ip_headers Cf-Connecting-IP X-Forwarded-For
        }
      '';

      virtualHosts =
        lib.mapAttrs' mkSite sites
        // guestVirtualHosts
        // {
          # One wildcard cert; Caddy >=2.10 reuses it for every subdomain site above.
          "*.${domain}" = {
            logFormat = journalLog;
            extraConfig = ''
              respond 404
            '';
          };
        };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ports.caddy-guest];

    my.crowdsec.caddy.enable = true;
    my.crowdsec.appsec.enable = true;

    services.prometheus.scrapeConfigs = [
      {
        job_name = "caddy";
        static_configs = [{targets = ["localhost:${toString ports.caddy-admin}"];}];
      }
    ];

    # maxmind_geolocation keeps the mmdb open until the matcher is cleaned up on reload.
    systemd.services.geoip-update.serviceConfig.ExecStartPost = "${pkgs.systemd}/bin/systemctl try-reload-or-restart caddy.service";

    services.grafana.provision.dashboards.settings.providers = [
      {
        name = "caddy";
        options.path = ./grafana;
        disableDeletion = false;
        updateIntervalSeconds = 30;
      }
    ];

    systemd.services.caddy = {
      after = ["network-online.target" "sops-nix.service"];
      wants = ["network-online.target"];

      serviceConfig = {
        EnvironmentFile = [
          config.sops.secrets.cloudflare_acme_credentials.path
          config.sops.templates."caddy-crowdsec.env".path
        ];
        NoNewPrivileges = lib.mkDefault true;
        PrivateTmp = lib.mkDefault true;
        ProtectHome = lib.mkDefault true;
        RestrictSUIDSGID = lib.mkDefault true;
        LockPersonality = lib.mkDefault true;
        RestrictRealtime = lib.mkDefault true;
        SystemCallArchitectures = lib.mkDefault "native";
        CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE" "CAP_NET_ADMIN"];
        ProtectClock = lib.mkDefault true;
        ProtectKernelLogs = lib.mkDefault true;
        ProtectKernelModules = lib.mkDefault true;
        ProtectKernelTunables = lib.mkDefault true;
        ProtectControlGroups = lib.mkDefault true;
        ProtectHostname = lib.mkDefault true;
        RestrictNamespaces = lib.mkDefault true;
        # Safe here unlike Traefik: plugins are compiled in, no Yaegi interpreter.
        MemoryDenyWriteExecute = lib.mkDefault true;
        RestrictAddressFamilies = lib.mkDefault ["AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK"];
        ProtectProc = lib.mkDefault "invisible";
        ProcSubset = lib.mkDefault "pid";
        UMask = lib.mkDefault "0077";
        SystemCallFilter = lib.mkDefault ["@system-service"];
        RemoveIPC = lib.mkDefault true;
        # PrivateUsers deliberately NOT set: breaks AmbientCapabilities=CAP_NET_BIND_SERVICE (see caddy/gcp-relay).
      };
    };
  };
}
