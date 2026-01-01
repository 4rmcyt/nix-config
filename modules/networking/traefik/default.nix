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
    enable = lib.mkEnableOption "Traefik reverse proxy with Authelia integration";

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
      # SSL certificate paths configuration - always set (used by Traefik and other services)
      my.security.ssl = {
        certPath = "/var/lib/acme/${domain}/fullchain.pem";
        keyPath = "/var/lib/acme/${domain}/key.pem";
      };
    }
    (lib.mkIf cfg.enable {
      # ACME/Let's Encrypt configuration - only when Traefik is enabled
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
      # Create traefik user and group
      users.users.traefik = {
        isSystemUser = true;
        group = "traefik";
        extraGroups = ["acme"]; # Access to ACME SSL certs
      };
      users.groups.traefik = {};

      # Traefik service
      services.traefik = {
        enable = true;

        staticConfigOptions = {
          # Entry points
          entryPoints = {
            web = {
              address = ":8080"; # Internal HTTP port
              http.redirections.entryPoint = {
                to = "websecure";
                scheme = "https";
              };
            };
            websecure = {
              address = ":8443"; # Internal HTTPS port
              http.tls.certResolver = "default";
            };
          };

          # API and dashboard
          api = {
            dashboard = true;
            insecure = false;
          };

          # Providers
          providers = {
            file = {
              directory = "/var/lib/traefik";
              watch = true;
            };
          };

          # Certificate resolvers (using existing certs)
          certificatesResolvers.default.acme = {
            inherit (config.my.defaults) email;
            storage = "/var/lib/traefik/acme.json";
            tlsChallenge = {};
          };

          # Logging
          log = {
            level = "INFO";
            filePath = "/var/log/traefik/traefik.log";
          };

          accessLog = {
            filePath = "/var/log/traefik/access.log";
          };
        };
      };

      # Dynamic configuration for Authelia middleware
      environment.etc."traefik/dynamic.yml".text = lib.generators.toYAML {} {
        http = {
          middlewares = {
            # Authelia forward auth middleware
            authelia = {
              forwardAuth = {
                address = "http://localhost:9000/api/authz/forward-auth";
                trustForwardHeader = true;
                authResponseHeaders = [
                  "Remote-User"
                  "Remote-Groups"
                  "Remote-Name"
                  "Remote-Email"
                ];
              };
            };

            # Security headers
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

            # Rate limiting
            rate-limit = {
              rateLimit = {
                average = 100;
                burst = 50;
              };
            };
          };

          # TLS configuration using existing certs
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

          # Routers for ALL services (forward auth OR OIDC)
          routers = {
            # Nixarr services (forward auth via Authelia)
            sonarr = {
              rule = "Host(`sonarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "sonarr";
              middlewares = ["authelia" "security-headers"];
              tls = {};
            };
            radarr = {
              rule = "Host(`radarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "radarr";
              middlewares = ["authelia" "security-headers"];
              tls = {};
            };
            prowlarr = {
              rule = "Host(`prowlarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "prowlarr";
              middlewares = ["authelia" "security-headers"];
              tls = {};
            };
            bazarr = {
              rule = "Host(`bazarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "bazarr";
              middlewares = ["authelia" "security-headers"];
              tls = {};
            };
            lidarr = {
              rule = "Host(`lidarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "lidarr";
              middlewares = ["authelia" "security-headers"];
              tls = {};
            };
            readarr = {
              rule = "Host(`readarr.${domain}`)";
              entryPoints = ["websecure"];
              service = "readarr";
              middlewares = ["authelia" "security-headers"];
              tls = {};
            };
            jellyseerr = {
              rule = "Host(`jellyseerr.${domain}`)";
              entryPoints = ["websecure"];
              service = "jellyseerr";
              middlewares = ["authelia" "security-headers"];
              tls = {};
            };

            # Services with native OIDC (no forward auth needed)
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
            grafana = {
              rule = "Host(`grafana.${domain}`)";
              entryPoints = ["websecure"];
              service = "grafana";
              middlewares = ["security-headers"];
              tls = {};
            };
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

            # Other services with forward auth
            homepage = {
              rule = "Host(`home.${domain}`)";
              entryPoints = ["websecure"];
              service = "homepage";
              middlewares = ["authelia" "security-headers"];
              tls = {};
            };
            microbin = {
              rule = "Host(`microbin.${domain}`)";
              entryPoints = ["websecure"];
              service = "microbin";
              middlewares = ["authelia" "security-headers"];
              tls = {};
            };

            # Infrastructure services
            authelia = {
              rule = "Host(`auth.${domain}`)";
              entryPoints = ["websecure"];
              service = "authelia";
              middlewares = ["security-headers"];
              tls = {};
            };
            lldap = {
              rule = "Host(`lldap.${domain}`)";
              entryPoints = ["websecure"];
              service = "lldap";
              middlewares = ["authelia" "security-headers"];
              tls = {};
            };
            vault = {
              rule = "Host(`vault.${domain}`)";
              entryPoints = ["websecure"];
              service = "vault";
              middlewares = ["authelia" "security-headers"];
              tls = {};
            };
            kuma = {
              rule = "Host(`kuma.${domain}`)";
              entryPoints = ["websecure"];
              service = "kuma";
              middlewares = ["authelia" "security-headers"];
              tls = {};
            };
            atuin = {
              rule = "Host(`atuin.${domain}`)";
              entryPoints = ["websecure"];
              service = "atuin";
              middlewares = ["authelia" "security-headers"];
              tls = {};
            };
            livesync = {
              rule = "Host(`livesync.${domain}`)";
              entryPoints = ["websecure"];
              service = "livesync";
              middlewares = ["authelia" "security-headers"];
              tls = {};
            };
          };

          # Services (backend servers)
          services = {
            # Nixarr services
            sonarr.loadBalancer.servers = [{url = "http://localhost:8989";}];
            radarr.loadBalancer.servers = [{url = "http://localhost:7878";}];
            prowlarr.loadBalancer.servers = [{url = "http://localhost:9696";}];
            bazarr.loadBalancer.servers = [{url = "http://localhost:6767";}];
            lidarr.loadBalancer.servers = [{url = "http://localhost:8686";}];
            readarr.loadBalancer.servers = [{url = "http://localhost:8787";}];
            jellyseerr.loadBalancer.servers = [{url = "http://localhost:5055";}];

            # Services with OIDC
            jellyfin.loadBalancer.servers = [{url = "http://localhost:8096";}];
            deluge.loadBalancer.servers = [{url = "http://localhost:8112";}];
            grafana.loadBalancer.servers = [{url = "http://localhost:3003";}];
            miniflux.loadBalancer.servers = [{url = "http://localhost:8086";}];
            kavita.loadBalancer.servers = [{url = "http://localhost:5000";}];
            audiobookshelf.loadBalancer.servers = [{url = "http://localhost:9292";}];

            # Other services
            homepage.loadBalancer.servers = [{url = "http://localhost:8082";}];
            microbin.loadBalancer.servers = [{url = "http://localhost:8069";}];

            # Infrastructure
            authelia.loadBalancer.servers = [{url = "http://localhost:9000";}];
            lldap.loadBalancer.servers = [{url = "http://localhost:17170";}];
            vault.loadBalancer.servers = [{url = "http://localhost:8222";}];
            kuma.loadBalancer.servers = [{url = "http://localhost:3001";}];
            atuin.loadBalancer.servers = [{url = "http://localhost:8881";}];
            livesync.loadBalancer.servers = [{url = "http://localhost:5984";}];
          };
        };
      };

      # Symlink dynamic config to traefik directory
      systemd.tmpfiles.rules = [
        "d /var/lib/traefik 0755 traefik traefik -"
        "d /var/log/traefik 0755 traefik traefik -"
        "L+ /var/lib/traefik/dynamic.yml - - - - /etc/traefik/dynamic.yml"
      ];

      # Firewall rules
      networking.firewall.allowedTCPPorts = [
        8080 # Traefik HTTP (internal)
        8443 # Traefik HTTPS (internal)
      ];

      # Ensure traefik starts after authelia and acme
      systemd.services.traefik = {
        after = ["authelia.service" "acme-${domain}.service"];
        wants = ["acme-${domain}.service"];
        serviceConfig = {
          # Allow traefik to read SSL certs from ACME
          SupplementaryGroups = ["acme"];
        };
      };
    })
  ];
}
