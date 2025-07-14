{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Create a file containing all the environment variables from secrets
  secretsEnvFile = pkgs.writeText "homepage-secrets.env" ''
    HOMEPAGE_VAR_SONARR_KEY=$(cat ${config.sops.secrets.homepage_sonarr_key.path})
    HOMEPAGE_VAR_RADARR_KEY=$(cat ${config.sops.secrets.homepage_radarr_key.path})
    HOMEPAGE_VAR_PROWLARR_KEY=$(cat ${config.sops.secrets.homepage_prowlarr_key.path})
    # ... add a line for each secret
  '';
in
{
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
              widgets = [
                {
                  type = "jellyfin";
                  url = "http://localhost:8096";
                  key = "${config.sops.secrets.homepage_jellyfin_key.path}";
                }
              ];
            };
          }
          {
            "Audiobookshelf" = {
              href = "https://audiobookshelf.labhome.work";
              description = "Audiobook & Podcast Server";
              icon = "audiobookshelf";
              widgets = [
                {
                  type = "audiobookshelf";
                  url = "http://localhost:8085";
                  key = "${config.sops.secrets.homepage_audiobookshelf_key.path}";
                }
              ];
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
                  key = "${config.sops.secrets.homepage_sonarr_key.path}";
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
                  key = "${config.sops.secrets.homepage_radarr_key.path}";
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
                  key = "${config.sops.secrets.homepage_prowlarr_key.path}";
                }
              ];
            };
          }
          {
            "Bazarr" = {
              icon = "bazarr.png";
              href = "https://bazarr.labhome.work/";
              widgets = [
                {
                  type = "bazarr";
                  url = "http://localhost:6767";
                  key = "${config.sops.secrets.homepage_bazarr_key.path}";
                }
              ];
            };
          }
          {
            "Jellyseerr" = {
              icon = "jellyseerr.png";
              href = "https://jellyseerr.labhome.work/";
              widgets = [
                {
                  type = "jellyseerr";
                  url = "http://localhost:5055/";
                  key = "${config.sops.secrets.homepage_jellyseerr_key.path}";
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
              widgets = [
                {
                  type = "nextcloud";
                  url = "http://localhost:8081";
                  key = "${config.sops.secrets.homepage_nextcloud_key.path}";
                }
              ];
            };
          }
          {
            "Paperless" = {
              href = "https://paperless.labhome.work";
              description = "Document Management";
              icon = "paperless-ngx";
              widgets = [
                {
                  type = "paperless";
                  url = "http://localhost:8888";
                  key = "${config.sops.secrets.homepage_paperless_key.path}";
                }
              ];
            };
          }
          {
            "Kavita" = {
              href = "https://kavita.labhome.work";
              description = "Ebook & Manga Library";
              icon = "kavita";
              widgets = [
                {
                  type = "kavita";
                  url = "http://localhost:5000";
                  key = "${config.sops.secrets.homepage_kavita_key.path}";
                }
              ];
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
              widgets = [
                {
                  type = "tailscale";
                  url = "http://localhost:41641";
                  key = "${config.sops.secrets.homepage_tailscale_key.path}";
                }
              ];
            };
          }
          {
            "Cloudflare Zero Trust" = {
              href = "https://one.dash.cloudflare.com";
              description = "Zero Trust Network Access";
              icon = "cloudflare-zero-trust";
            };
          }
          {
            "Cloudflare DNS" = {
              href = "https://dash.cloudflare.com/8239dd1bb0d0bfedf13673a195df59cf/home";
              description = "DNS Management";
              icon = "cloudflare-dns";
              widgets = [
                {
                  type = "cloudflare";
                  url = "http://localhost:8080";
                  key = "${config.sops.secrets.homepage_cloudflared_key.path}";
                }
              ];
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
