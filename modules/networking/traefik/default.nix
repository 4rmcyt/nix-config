{
  config,
  lib,
  ...
}: let
  cfg = config.my.traefik;
  inherit (config.my.defaults) domain;
  inherit (config.my.security.ssl) certPath keyPath;
in {
  options.my.traefik = {
    enable = lib.mkEnableOption "Traefik reverse proxy";

    entryPoints = lib.mkOption {
      type = lib.types.attrs;
      default = {
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
        };
      };
      description = "Traefik entry points configuration";
    };
  };

  config = lib.mkMerge [
    {
      # SSL certificate paths — always set (used by Traefik and other services)
      my.security.ssl = {
        certPath = "/var/lib/acme/${domain}/fullchain.pem";
        keyPath = "/var/lib/acme/${domain}/key.pem";
      };
    }
    (lib.mkIf cfg.enable {
      # ACME/Let's Encrypt via Cloudflare DNS-01 challenge
      sops.secrets.cloudflare_acme_credentials = {
        sopsFile = ../../../secrets/cloudflare_acme_credentials.env;
        owner = "acme";
        group = "acme";
        mode = "0400";
        format = "dotenv";
      };

      users.users.acme = {
        isSystemUser = true;
        group = "acme";
      };
      users.groups.acme = {};

      security.acme = {
        acceptTerms = true;
        defaults.email = config.my.defaults.email;

        certs.${domain} = {
          domain = "*.${domain}";
          extraDomainNames = [domain];
          dnsProvider = "cloudflare";
          credentialsFile = config.sops.secrets.cloudflare_acme_credentials.path;
          keyType = "ec256";
          group = "traefik";
          postRun = "systemctl reload traefik.service";
        };
      };

      users.users.traefik = {
        isSystemUser = true;
        group = "traefik";
        extraGroups = ["acme"];
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
            };
          };

          api = {
            dashboard = true;
            insecure = false;
          };

          providers = {
            file = {
              directory = "/var/lib/traefik";
              watch = true;
            };
          };

          log = {
            level = "INFO";
            filePath = "/var/log/traefik/traefik.log";
          };

          accessLog = {
            filePath = "/var/log/traefik/access.log";
          };
        };
      };

      # Dynamic configuration — TLS certs + routers (no Authelia, Tailscale = auth)
      environment.etc."traefik/dynamic.yml".text = lib.generators.toYAML {} {
        # TLS store must be a top-level key, not nested under http
        tls = {
          certificates = [
            {
              certFile = certPath;
              keyFile = keyPath;
            }
          ];
          stores.default.defaultCertificate = {
            certFile = certPath;
            keyFile = keyPath;
          };
        };

        http = {
          middlewares = {
            security-headers = {
              headers = {
                frameDeny = true;
                browserXssFilter = true;
                contentTypeNosniff = true;
                forceSTSHeader = true;
                stsIncludeSubdomains = true;
                stsPreload = true;
                stsSeconds = 31536000;
                customFrameOptionsValue = "SAMEORIGIN";
              };
            };
          };

          routers = {
            traefik-dashboard = {
              rule = "Host(`traefik.${domain}`)";
              entryPoints = ["websecure"];
              service = "api@internal";
              middlewares = ["security-headers"];
              tls = {};
            };

            # Nixarr
            sonarr = {
              rule = "Host(`sonarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "sonarr";
              middlewares = ["security-headers"];
              tls = {};
            };
            radarr = {
              rule = "Host(`radarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "radarr";
              middlewares = ["security-headers"];
              tls = {};
            };
            prowlarr = {
              rule = "Host(`prowlarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "prowlarr";
              middlewares = ["security-headers"];
              tls = {};
            };
            bazarr = {
              rule = "Host(`bazarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "bazarr";
              middlewares = ["security-headers"];
              tls = {};
            };
            lidarr = {
              rule = "Host(`lidarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "lidarr";
              middlewares = ["security-headers"];
              tls = {};
            };
            readarr = {
              rule = "Host(`readarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "readarr";
              middlewares = ["security-headers"];
              tls = {};
            };
            jellyseerr = {
              rule = "Host(`jellyseerr.${domain}`)";
              entryPoints = ["websecure"];
              service = "jellyseerr";
              middlewares = ["security-headers"];
              tls = {};
            };

            # Media
            jellyfin = {
              rule = "Host(`jellyfin.${domain}`)";
              entryPoints = ["websecure"];
              service = "jellyfin";
              middlewares = ["security-headers"];
              tls = {};
            };
            deluge = {
              rule = "Host(`deluge.${domain}`)";
              entryPoints = ["websecure"];
              service = "deluge";
              middlewares = ["security-headers"];
              tls = {};
            };

            # Monitoring
            grafana = {
              rule = "Host(`grafana.${domain}`)";
              entryPoints = ["websecure"];
              service = "grafana";
              middlewares = ["security-headers"];
              tls = {};
            };
            kuma = {
              rule = "Host(`kuma.${domain}`)";
              entryPoints = ["websecure"];
              service = "kuma";
              middlewares = ["security-headers"];
              tls = {};
            };

            # Reading
            miniflux = {
              rule = "Host(`miniflux.${domain}`)";
              entryPoints = ["websecure"];
              service = "miniflux";
              middlewares = ["security-headers"];
              tls = {};
            };
            kavita = {
              rule = "Host(`kavita.${domain}`)";
              entryPoints = ["websecure"];
              service = "kavita";
              middlewares = ["security-headers"];
              tls = {};
            };
            audiobookshelf = {
              rule = "Host(`audiobookshelf.${domain}`)";
              entryPoints = ["websecure"];
              service = "audiobookshelf";
              middlewares = ["security-headers"];
              tls = {};
            };

            # Productivity
            homepage = {
              rule = "Host(`home.${domain}`)";
              entryPoints = ["websecure"];
              service = "homepage";
              middlewares = ["security-headers"];
              tls = {};
            };
            microbin = {
              rule = "Host(`microbin.${domain}`)";
              entryPoints = ["websecure"];
              service = "microbin";
              middlewares = ["security-headers"];
              tls = {};
            };
            vaultwarden = {
              rule = "Host(`vault.${domain}`)";
              entryPoints = ["websecure"];
              service = "vaultwarden";
              middlewares = ["security-headers"];
              tls = {};
            };
            atuin = {
              rule = "Host(`atuin.${domain}`)";
              entryPoints = ["websecure"];
              service = "atuin";
              middlewares = ["security-headers"];
              tls = {};
            };
            livesync = {
              rule = "Host(`livesync.${domain}`)";
              entryPoints = ["websecure"];
              service = "livesync";
              middlewares = ["security-headers"];
              tls = {};
            };
          };

          services = {
            # Nixarr
            sonarr.loadBalancer.servers = [{url = "http://localhost:8989";}];
            radarr.loadBalancer.servers = [{url = "http://localhost:7878";}];
            prowlarr.loadBalancer.servers = [{url = "http://localhost:9696";}];
            bazarr.loadBalancer.servers = [{url = "http://localhost:6767";}];
            lidarr.loadBalancer.servers = [{url = "http://localhost:8686";}];
            readarr.loadBalancer.servers = [{url = "http://localhost:8787";}];
            jellyseerr.loadBalancer.servers = [{url = "http://localhost:5055";}];

            # Media
            jellyfin.loadBalancer.servers = [{url = "http://localhost:8096";}];
            deluge.loadBalancer.servers = [{url = "http://localhost:8112";}];

            # Monitoring
            grafana.loadBalancer.servers = [{url = "http://localhost:3003";}];
            kuma.loadBalancer.servers = [{url = "http://localhost:3001";}];

            # Reading
            miniflux.loadBalancer.servers = [{url = "http://localhost:8086";}];
            kavita.loadBalancer.servers = [{url = "http://localhost:5000";}];
            audiobookshelf.loadBalancer.servers = [{url = "http://localhost:9292";}];

            # Productivity
            homepage.loadBalancer.servers = [{url = "http://localhost:8082";}];
            microbin.loadBalancer.servers = [{url = "http://localhost:8069";}];
            vaultwarden.loadBalancer.servers = [{url = "http://localhost:8222";}];
            atuin.loadBalancer.servers = [{url = "http://localhost:8881";}];
            livesync.loadBalancer.servers = [{url = "http://localhost:5984";}];
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/traefik 0755 traefik traefik -"
        "d /var/log/traefik 0755 traefik traefik -"
        "L+ /var/lib/traefik/dynamic.yml - - - - /etc/traefik/dynamic.yml"
      ];

      # Traefik after ACME cert is ready
      systemd.services.traefik = {
        after = ["acme-${domain}.service"];
        wants = ["acme-${domain}.service"];
        serviceConfig = {
          SupplementaryGroups = ["acme"];
        };
      };
    })
  ];
}
