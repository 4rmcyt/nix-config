{ config, pkgs, lib, ... }:

{
  # 1. CONFIGURE THE SERVICE LAYOUT
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
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
                key = "{{HOMEPAGE_VAR_JELLYFIN_KEY}}";
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
                key = "{{HOMEPAGE_VAR_AUDIOBOOKSHELF_KEY}}";
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
                key = "{{HOMEPAGE_VAR_SONARR_KEY}}";
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
                key = "{{HOMEPAGE_VAR_RADARR_KEY}}";
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
                key = "{{HOMEPAGE_VAR_PROWLARR_KEY}}";
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
                key = "{{HOMEPAGE_VAR_BAZARR_KEY}}";
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
                key = "{{HOMEPAGE_VAR_JELLYSEERR_KEY}}";
              }];
            };
          }
          {
            "Lidarr" = {
              icon = "lidarr.png";
              href = "https://lidarr.labhome.work/";
              widgets = [{
                type = "lidarr";
                url = "http://localhost:8686";
                key = "{{HOMEPAGE_VAR_LIDARR_KEY}}";
              }];
            };
          }
          {
            "Readarr" = {
              icon = "readarr.png";
              href = "https://readarr.labhome.work/";
              widgets = [{
                type = "readarr";
                url = "http://localhost:8787";
                key = "{{HOMEPAGE_VAR_READARR_KEY}}";
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
                key = "{{HOMEPAGE_VAR_NEXTCLOUD_KEY}}";
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
                key = "{{HOMEPAGE_VAR_PAPERLESS_KEY}}";
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
                key = "{{HOMEPAGE_VAR_KAVITA_KEY}}";
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
                key = "{{HOMEPAGE_VAR_MINIFLUX_KEY}}";
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
                password = "{{HOMEPAGE_VAR_GRAFANA_ADMIN_PASSWORD}}";
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
              icon = "homeassistant";
              widgets = [{
                type = "homeassistant";
                url = "http://localhost:8123";
                key = "{{HOMEPAGE_VAR_HASS_KEY}}";
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
                profile = "{{HOMEPAGE_VAR_NEXTDNS_PROFILE_ID}}";
                key = "{{HOMEPAGE_VAR_NEXTDNS_KEY}}";
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
                deviceid = "{{HOMEPAGE_VAR_TAILSCALE_DEVICE_ID}}";
                key = "{{HOMEPAGE_VAR_TAILSCALE_KEY}}";
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
                accountid = "{{HOMEPAGE_VAR_CLOUDFLARED_ACCOUNT_ID}}";
                tunnelid = "{{HOMEPAGE_VAR_CLOUDFLARED_TUNNEL_ID}}";
                key = "{{HOMEPAGE_VAR_CLOUDFLARED_KEY}}";
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
          latitude = "{{HOMEPAGE_VAR_LATITUDE}}";
          longitude = "{{HOMEPAGE_VAR_LONGITUDE}}";
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

  # 2. CONFIGURE THE UNDERLYING SYSTEMD SERVICE
  systemd.services.homepage-dashboard.serviceConfig = {
    Environment = [
      "HOMEPAGE_ALLOWED_HOSTS=localhost,127.0.0.1,192.168.1.165,home.labhome.work"
    ];

    # This is the corrected syntax for LoadCredential.
    # It is a list of strings, each in the format "KEY:VALUE".
    LoadCredential = [
      "HOMEPAGE_VAR_JELLYSEERR_KEY:${config.sops.secrets.homepage_jellyseerr_key.path}"
      "HOMEPAGE_VAR_LIDARR_KEY:${config.sops.secrets.homepage_lidarr_key.path}"
      "HOMEPAGE_VAR_PROWLARR_KEY:${config.sops.secrets.homepage_prowlarr_key.path}"
      "HOMEPAGE_VAR_RADARR_KEY:${config.sops.secrets.homepage_radarr_key.path}"
      "HOMEPAGE_VAR_READARR_KEY:${config.sops.secrets.homepage_readarr_key.path}"
      "HOMEPAGE_VAR_SONARR_KEY:${config.sops.secrets.homepage_sonarr_key.path}"
      "HOMEPAGE_VAR_BAZARR_KEY:${config.sops.secrets.homepage_bazarr_key.path}"
      "HOMEPAGE_VAR_PAPERLESS_KEY:${config.sops.secrets.homepage_paperless_key.path}"
      "HOMEPAGE_VAR_MINIFLUX_KEY:${config.sops.secrets.homepage_miniflux_key.path}"
      "HOMEPAGE_VAR_NEXTCLOUD_KEY:${config.sops.secrets.homepage_nextcloud_key.path}"
      "HOMEPAGE_VAR_TAILSCALE_KEY:${config.sops.secrets.homepage_tailscale_key.path}"
      "HOMEPAGE_VAR_TAILSCALE_DEVICE_ID:${config.sops.secrets.homepage_tailscale_device_id.path}"
      "HOMEPAGE_VAR_CLOUDFLARED_ACCOUNT_ID:${config.sops.secrets.homepage_cloudflared_account_id.path}"
      "HOMEPAGE_VAR_CLOUDFLARED_KEY:${config.sops.secrets.homepage_cloudflared_key.path}"
      "HOMEPAGE_VAR_CLOUDFLARED_TUNNEL_ID:${config.sops.secrets.homepage_cloudflared_tunnel_id.path}"
      "HOMEPAGE_VAR_NEXTDNS_PROFILE_ID:${config.sops.secrets.homepage_nextdns_profile_id.path}"
      "HOMEPAGE_VAR_NEXTDNS_KEY:${config.sops.secrets.homepage_nextdns_key.path}"
      "HOMEPAGE_VAR_GRAFANA_KEY:${config.sops.secrets.homepage_grafana_key.path}"
      "HOMEPAGE_VAR_JELLYFIN_KEY:${config.sops.secrets.homepage_jellyfin_key.path}"
      "HOMEPAGE_VAR_AUDIOBOOKSHELF_KEY:${config.sops.secrets.homepage_audiobookshelf_key.path}"
      "HOMEPAGE_VAR_KAVITA_KEY:${config.sops.secrets.homepage_kavita_key.path}"
      "HOMEPAGE_VAR_LATITUDE:${config.sops.secrets.homepage_latitude.path}"
      "HOMEPAGE_VAR_LONGITUDE:${config.sops.secrets.homepage_longitude.path}"
      "HOMEPAGE_VAR_GRAFANA_ADMIN_PASSWORD:${config.sops.secrets.homepage_grafana_admin_password.path}"
      "HOMEPAGE_VAR_HASS_KEY:${config.sops.secrets.homepage_hass_key.path}"
    ];
  };
}
