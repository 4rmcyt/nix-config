{
  config,
  pkgs,
  lib,
  ...
}:
{
  # 1. Main application configuration
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    envFile = config.sops.secrets.homepage_secrets.path;
    services = [
      {
        "Media" = [
          {
            "Jellyfin" = {
              href = "https://jellyfin.labhome.work";
              description = "Media Server";
              icon = "jellyfin";
              widgets = [{
                type = "jellyfin";
                url = "http://localhost:8096";
                key = "{{HOMEPAGE_VAR_homepage_jellyfin_key}}";
              }];
            };
          }
          {
            "Audiobookshelf" = {
              href = "https://audiobookshelf.labhome.work";
              description = "Audiobook & Podcast Server";
              icon = "audiobookshelf";
              widgets = [{
                type = "audiobookshelf";
                url = "http://localhost:8085";
                key = "{{HOMEPAGE_VAR_homepage_audiobookshelf_key}}";
              }];
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
              widgets = [{
                type = "sonarr";
                url = "http://localhost:8989";
                key = "{{HOMEPAGE_VAR_homepage_sonarr_key}}";
              }];
            };
          }
          {
            "Radarr" = {
              icon = "radarr.png";
              href = "https://movies.labhome.work/";
              widgets = [{
                type = "radarr";
                url = "http://localhost:7878";
                key = "{{HOMEPAGE_VAR_homepage_radarr_key}}";
              }];
            };
          }
          {
            "Transmission" = {
              icon = "transmission.png";
              href = "https://transmission.labhome.work/";
              widgets = [{
                type = "transmission";
                url = "http://localhost:9091";
              }];
            };
          }
          {
            "Prowlarr" = {
              icon = "prowlarr.png";
              href = "https://prowlarr.labhome.work/";
              widgets = [{
                type = "prowlarr";
                url = "http://localhost:9696";
                key = "{{HOMEPAGE_VAR_homepage_prowlarr_key}}";
              }];
            };
          }
          {
            "Bazarr" = {
              icon = "bazarr.png";
              href = "https://bazarr.labhome.work/";
              widgets = [{
                type = "bazarr";
                url = "http://localhost:6767";
                key = "{{HOMEPAGE_VAR_homepage_bazarr_key}}";
              }];
            };
          }
          {
            "Jellyseerr" = {
              icon = "jellyseerr.png";
              href = "https://jellyseerr.labhome.work/";
              widgets = [{
                type = "jellyseerr";
                url = "http://localhost:5055/";
                key = "{{HOMEPAGE_VAR_homepage_jellyseerr_key}}";
              }];
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
              widgets = [{
                type = "nextcloud";
                url = "http://localhost:8081";
                key = "{{HOMEPAGE_VAR_homepage_nextcloud_key}}";
              }];
            };
          }
          {
            "Paperless" = {
              href = "https://paperless.labhome.work";
              description = "Document Management";
              icon = "paperless-ngx";
              widgets = [{
                type = "paperless";
                url = "http://localhost:8888";
                key = "{{HOMEPAGE_VAR_homepage_paperless_key}}";
              }];
            };
          }
          {
            "Kavita" = {
              href = "https://kavita.labhome.work";
              description = "Ebook & Manga Library";
              icon = "kavita";
              widgets = [{
                type = "kavita";
                url = "http://localhost:5000";
                key = "{{HOMEPAGE_VAR_homepage_kavita_key}}";
              }];
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
              widgets = [{
                type = "miniflux";
                url = "http://localhost:8086";
                key = "{{HOMEPAGE_VAR_homepage_miniflux_key}}";
              }];
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
      {
        "Monitoring & Analytics" = [
          {
            "Grafana" = {
              href = "http://192.168.1.165:3000";
              description = "Real-time System Dashboard";
              icon = "grafana";
              widgets = [{
                type = "grafana";
                url = "http://localhost:3000";
                username = "admin";
                password = "{{HOMEPAGE_VAR_homepage_grafana_admin_password}}";
              }];
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
        ];
      }
      {
        "Smart Home & IoT" = [
          {
            "Home Assistant" = {
              href = "https://hass.labhome.work";
              description = "Home Automation";
              icon = "home-assistant";
              widgets = [{
                type = "home-assistant";
                url = "http://localhost:8123";
                key = "{{HOMEPAGE_VAR_homepage_hass_key}}";
              }];
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
            "NextDns" = {
              href = "https://my.nextdns.io/";
              description = "Nextdns Dashboard";
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/nextdns.svg";
              widget = {
                type = "nextdns";
                profile = "{{HOMEPAGE_VAR_homepage_nextdns_profile_id}}";
                key = "{{HOMEPAGE_VAR_homepage_nextdns_key}}";
              };
            };
          }
          {
            "Tailscale" = {
              href = "https://login.tailscale.com/admin/machines";
              description = "Mesh VPN Administration";
              icon = "tailscale";
              widget = {
                type = "tailscale";
                deviceid = "{{HOMEPAGE_VAR_homepage_tailscale_device_id}}";
                key = "{{HOMEPAGE_VAR_homepage_tailscale_key}}";
              };
            };
          }
          {
            "Cloudflare Tunnels" = {
              href = "https://one.dash.cloudflare.com/8239dd1bb0d0bfedf13673a195df59cf/networks/tunnels";
              description = "Cloudflare Tunnels Management";
              icon = "cloudflare-zero-trust";
              widget = {
                type = "cloudflared";
                accountid = "{{HOMEPAGE_VAR_homepage_cloudflared_account_id}}";
                tunnelid = "{{HOMEPAGE_VAR_homepage_cloudflared_tunnel_id}}";
                key = "{{HOMEPAGE_VAR_homepage_cloudflared_key}}";
              };
            };
          }
        ];
      }
    ];

    widgets = [
      {
        search = {
          provider = "google";
          target = "_blank";
        };
      }
      {
        resources = {
          label = "system";
          cpu = true;
          memory = true;
        };
      }
      {
        resources = {
          label = "storage";
          disk = [ "/data" ];
        };
      }
      {
        openmeteo = {
          label = "Calgary";
          timezone = "America/Edmonton";
          latitude = "{{HOMEPAGE_VAR_homepage_latitude}}";
          longitude = "{{HOMEPAGE_VAR_homepage_longitude}}";
          units = "metric";
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

  # This block correctly injects both the secrets file and the extra
  # environment variable into the systemd service.
  systemd.services.homepage-dashboard.serviceConfig = {
    # This points to the environment file created by sops-nix for your homepage secrets.
    EnvironmentFile = lib.mkForce config.sops.secrets.homepage_secrets.path;
    # This adds the allowed hosts variable.
    Environment = [
      "HOMEPAGE_ALLOWED_HOSTS=localhost,127.0.0.1,192.168.1.165,home.labhome.work"
    ];
  };
}
