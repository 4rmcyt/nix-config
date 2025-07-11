{ config, pkgs, lib, ... }:

{ 
  #   age.secrets = {
  #   sonarrApiKey.file = ./secrets/sonarrApiKey.age;
  #   radarrApiKey.file = ./secrets/radarrApiKey.age;
  #   bazarrApiKey.file = ./secrets/bazarrApiKey.age;
  #   prowlarrApiKey.file = ./secrets/prowlarrApiKey.age;
  #   jellyfinApiKey.file = ./secrets/jellyfinApiKey.age;
  #   jellyseerrApiKey.file = ./secrets/jellyseerrApiKey.age;
  #   truenasApiKey.file = ./secrets/truenasApiKey.age;
  #   adguardPass.file = ./secrets/adguardPass.age;
  #   transmissionPwd.file = ./secrets/transmissionPwd.age;
  #   opnsenseUser.file = ./secrets/opnsenseUser.age;
  #   opnsensePass.file = ./secrets/opnsensePass.age;
  # };
  # age-template.files."hompage-keys.env" = {
  #   vars = {
  #     sonarrKey = config.age.secrets.sonarrApiKey.path;
  #     radarrKey = config.age.secrets.radarrApiKey.path;
  #     bazarrKey = config.age.secrets.bazarrApiKey.path;
  #     prowlarrKey = config.age.secrets.prowlarrApiKey.path;
  #     jellyfinKey = config.age.secrets.jellyfinApiKey.path;
  #     jellyseerrKey = config.age.secrets.jellyseerrApiKey.path;
  #     truenasKey = config.age.secrets.truenasApiKey.path;
  #     adguardPass = config.age.secrets.adguardPass.path;
  #     opnsenseUser = config.age.secrets.opnsenseUser.path;
  #     opnsensePass = config.age.secrets.opnsensePass.path;
  #     transmissionPwd = config.age.secrets.transmissionPwd.path;
  #   };

  #   content = ''
  #     HOMEPAGE_VAR_SONARR_KEY="$sonarrKey"
  #     HOMEPAGE_VAR_RADARR_KEY="$radarrKey"
  #     HOMEPAGE_VAR_PROWLARR_KEY="$prowlarrKey"
  #     HOMEPAGE_VAR_BAZARR_KEY="$bazarrKey"
  #     HOMEPAGE_VAR_JELLYFIN_KEY="$jellyfinKey"
  #     HOMEPAGE_VAR_JELLYSEERR_KEY="$jellyseerrKey"
  #     HOMEPAGE_VAR_TRUENAS_KEY="$truenasKey"
  #     HOMEPAGE_VAR_ADGUARD_PWD="$adguardPass"
  #     HOMEPAGE_VAR_OPNSENSE_USER="$opnsenseUser"
  #     HOMEPAGE_VAR_OPNSENSE_PWD="$opnsensePass"
  #     HOMEPAGE_VAR_TRANSMISSION_PWD="$transmissionPwd"
  #   '';
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;

    # Enhanced service configuration with external domain URLs
    services = [
      {
        "Media" = [
          {
            "Jellyfin" = {
              href = "https://jellyfin.labhome.work";
              description = "Media Server";
              icon = "jellyfin";
            };
          }
          {
            "Audiobookshelf" = {
              href = "https://audiobookshelf.labhome.work";
              description = "Audiobook & Podcast Server";
              icon = "audiobookshelf";
            };
          }
        ];
      }
      {
        "Arrs" = [
          {
            "Sonarr" = {
              icon = "sonarr.png";

              href = "https://tv.labhome.work/";
              widgets = [
                {
                  type = "sonarr";
                  url = "http://localhost:8989";
                }
              ];
            };
          }
          {
            "Radarr" = {
              icon = "radarr.png";

              href = "https://movies.labhome.work/";
              widgets = [
                {
                  type = "radarr";
                  url = "http://localhost:7878";
                }
              ];
            };
          }
          {
            "Transmission" = {
              icon = "transmission.png";
              href = "https://transmission.labhome.work/";
              widgets = [
                {
                  type = "transmission";
                  url = "http://localhost:9091";
                }
              ];
            };
          }
          {
            "Prowlarr" = {
              icon = "prowlarr.png";
              href = "https://prowlarr.labhome.work/";
              widgets = [
                {
                  type = "prowlarr";
                  url = "http://localhost:9696";
                }
              ];
            };
          }
          {
            "Bazarr" = {
              icon = "bazarr.png";
              href = "htts://bazarr.labhome.work/";
              widgets = [
                {
                  type = "bazarr";
                  url = "http://localhost:6767";
                }
              ];
            };
          }
            "Jellyseerr" = {
              icon = "jellyseerr.png";
              href = "https://jellyseerr.abhome.work/";
              widgets = [
                {
                  type = "jellyseerr";
                  url = "http://localhost:5055/";
                  # key = "{{HOMEPAGE_VAR_JELLYSEERR_KEY}}";
                }
              ];
            };
          }
        ];
      }
      {
        "Storage & Documents" = [
          {
            "Nextcloud" = {
              href = "https://nextcloud.labhome.work/";
              description = "File Storage & Collaboration";
              icon = "nextcloud";
            };
          }
          {
            "Paperless" = {
              href = "https://paperless.labhome.work";
              description = "Document Management";
              icon = "paperless-ngx";
            };
          }
          {
            "Kavita" = {
              href = "https://kavita.labhome.work";
              description = "Ebook & Manga Library";
              icon = "kavita";
            };
          }
        ];
      }
      {
        "Productivity Tools" = [
          {
            "Microbin" = {
              href = "https://paste.labhome.work";
              description = "Pastebin Service";
              icon = "microbin";
            };
          }
          {
            "Miniflux" = {
              href = "https://rss.labhome.work";
              description = "RSS Reader";
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/miniflux.svg";
            };
          }
          {
            "Radicale" = {
              href = "https://cal.labhome.work";
              description = "Calendar & Contacts";
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/radicale.svg";
            };
          }
        ];
      }
      # Update the monitoring section to use working tools:
      {
        "Monitoring & Analytics" = [
          {
            "Grafana" = {
              href = "http://192.168.1.165:3000";
              description = "Real-time System Dashboard";
              icon = "grafana";
            };
          }
          {
            "Prometheus" = {
              href = "http://192.168.1.165:9090";
              description = "Metrics & Alerting";
              icon = "prometheus";
            };
          }
          {
            "Node Exporter" = {
              href = "http://192.168.1.165:9100/metrics";
              description = "System Metrics (Raw)";
              icon = "prometheus";
            };
          }
          {
            "NextDns" = {
              href = "https://my.nextdns.io/";
              description = "Nextdns Dashboard";
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/nextdns.svg";
            };
          }
        ];
      }
      {
        "Smart Home & IoT" = [
          {
            "Home Assistant" = {
              href = "https://hass.labhome.work";
              description = "Home Automation";
              icon = "home-assistant";
            };
          }
          {
            "Mosquitto MQTT" = {
              href = "http://192.168.1.165:1883";
              description = "MQTT Broker";
              icon = "mqtt";
            };
          }
        ];
      }
      {
        "Infrastructure & Security" = [
          {
            "Keycloak" = {
              href = "https://keycloak.labhome.work";
              description = "Identity & Access Management";
              icon = "keycloak";
            };
          }
          {
            "Tailscale" = {
              href = "https://login.tailscale.com/admin/machines";
              description = "Mesh VPN Administration";
              icon = "tailscale";
            };
          }
        ];
      }
    ];

    widgets = [
      {
        "system" = {
          "cpu" = true;
          "memory" = true;
          "disk" = "/";
        };
      }
      {
        "datetime" = {
          "text_size" = "xl";
          "format" = {
            "dateStyle" = "long";
            "timeStyle" = "short";
            "hour12" = false;
          };
        };
      }
    ];

    bookmarks = [
      {
        "External Services" = [
          {
            "Cloudflare" = [
              {
                "name" = "Dashboard";
                "href" = "https://dash.cloudflare.com";
              }
              {
                "name" = "Zero Trust";
                "href" = "https://one.dash.cloudflare.com";
              }
            ];
          }
          {
            "Tailscale" = [
              {
                "name" = "Admin Console";
                "href" = "https://dash.cloudflare.com/8239dd1bb0d0bfedf13673a195df59cf/home";
                "icon" = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/cloudflare.svg";
              }
              {
                "name" = "ACL Editor";
                "href" = "https://login.tailscale.com/admin/acls";
                "icon" = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/tailscale-light.svg";
              }
            ];
          }
          {
            "GitHub" = [
              {
                "name" = "GitHub Server Config";
                "href" = "https://github.com/your-username/server-config";
                "icon" = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/github-light.svg";
              }
            ];
          }
        ];
      }
    ];
  };

  systemd.services.homepage-dashboard.environment = {
    HOMEPAGE_ALLOWED_HOSTS = lib.mkForce "localhost,127.0.0.1,192.168.1.165,home.labhome.work";
  };
}