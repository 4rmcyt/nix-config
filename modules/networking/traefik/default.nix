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
            resolvers = ["1.1.1.1:53" "8.8.8.8:53"];
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
          };

          routers = {
            traefik-dashboard = {
              rule = "Host(`traefik.${domain}`)";
              entryPoints = ["websecure"];
              service = "api@internal";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };

            # Nixarr
            sonarr = {
              rule = "Host(`sonarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "sonarr";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };
            radarr = {
              rule = "Host(`radarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "radarr";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };
            prowlarr = {
              rule = "Host(`prowlarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "prowlarr";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };
            bazarr = {
              rule = "Host(`bazarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "bazarr";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };
            lidarr = {
              rule = "Host(`lidarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "lidarr";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };
            readarr = {
              rule = "Host(`readarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "readarr";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };

            # Media
            jellyfin = {
              rule = "Host(`jellyfin.${domain}`)";
              entryPoints = ["websecure"];
              service = "jellyfin";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };
            qb = {
              rule = "Host(`qb.${domain}`)";
              entryPoints = ["websecure"];
              service = "qb";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };
            tdarr = {
              rule = "Host(`tdarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "tdarr";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };

            # Monitoring
            grafana = {
              rule = "Host(`grafana.${domain}`)";
              entryPoints = ["websecure"];
              service = "grafana";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };

            # Reading
            miniflux = {
              rule = "Host(`miniflux.${domain}`)";
              entryPoints = ["websecure"];
              service = "miniflux";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };
            kavita = {
              rule = "Host(`kavita.${domain}`)";
              entryPoints = ["websecure"];
              service = "kavita";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };
            audiobookshelf = {
              rule = "Host(`audiobookshelf.${domain}`)";
              entryPoints = ["websecure"];
              service = "audiobookshelf";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };

            # Smart home
            hass = {
              rule = "Host(`hass.${domain}`)";
              entryPoints = ["websecure"];
              service = "hass";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };

            # Productivity
            homepage = {
              rule = "Host(`home.${domain}`)";
              entryPoints = ["websecure"];
              service = "homepage";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };
            microbin = {
              rule = "Host(`microbin.${domain}`)";
              entryPoints = ["websecure"];
              service = "microbin";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };
            vaultwarden = {
              rule = "Host(`vault.${domain}`)";
              entryPoints = ["websecure"];
              service = "vaultwarden";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };
            atuin = {
              rule = "Host(`atuin.${domain}`)";
              entryPoints = ["websecure"];
              service = "atuin";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };
            livesync = {
              rule = "Host(`livesync.${domain}`)";
              entryPoints = ["websecure"];
              service = "livesync";
              middlewares = ["security-headers"];
              tls.certResolver = "default";
            };
          };

          services = {
            # Nixarr
            sonarr.loadBalancer.servers = [{url = "http://localhost:8990";}];
            radarr.loadBalancer.servers = [{url = "http://localhost:7878";}];
            prowlarr.loadBalancer.servers = [{url = "http://localhost:9696";}];
            bazarr.loadBalancer.servers = [{url = "http://localhost:6767";}];
            lidarr.loadBalancer.servers = [{url = "http://localhost:8686";}];
            readarr.loadBalancer.servers = [{url = "http://localhost:8787";}];

            # Media
            jellyfin.loadBalancer.servers = [{url = "http://localhost:8096";}];
            qb.loadBalancer.servers = [{url = "http://localhost:8081";}];
            tdarr.loadBalancer.servers = [{url = "http://localhost:8265";}];

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

    # Cloudflare credentials injected as environment variables
    systemd.services.traefik.serviceConfig.EnvironmentFile =
      config.sops.secrets.cloudflare_acme_credentials.path;
  };
}
