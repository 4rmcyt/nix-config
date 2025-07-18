{
  config,
  pkgs,
  lib,
  ...
}:
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
                  key = "${config.sops.secrets.sonarr_key.path}";
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
                  key = "${config.sops.secrets.radarr_key.path}";
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
                  key = "${config.sops.secrets.prowlarr_key.path}";
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
                  key = "${config.sops.secrets.bazarr_key.path}";
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
                  key = "${config.sops.secrets.jellyseerr_key.path}";
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
              widgets = [
                {
                  type = "miniflux";
                  url = "http://localhost:8086";
                  key = "${config.sops.secrets.homepage_miniflux_key.path}";
                }
              ];
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
              widgets = [
                {
                  type = "grafana";
                  url = "http://localhost:3000";
                  username = "admin";
                  password = "${config.sops.secrets.grafana_admin_password.path}";
                }
              ];
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
              widgets = [
                {
                  type = "home-assistant";
                  url = "http://localhost:8123";
                  key = "${config.sops.secrets.homepage_hass_key.path}";
                }
              ];
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
                  profile = config.sops.secrets.homepage_nextdns_profile_id.path;
                  key = config.sops.secrets.homepage_nextdns_key.path; 
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
                deviceid = config.sops.secrets.homepage_tailscale_device_id.path;
                key = config.sops.secrets.homepage_tailscale_key.path;
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
                accountid = config.sops.secrets.homepage_cloudflared_account_id.path;
                tunnelid = config.sops.secrets.homepage_cloudflared_tunnel_id.path;
                key = config.sops.secrets.homepage_cloudflared_key.path;
              };
            };
          }
        ];
      }
    ];

    widgets = [
      { search = { provider = "google"; target = "_blank"; }; }
      { resources = { label = "system"; cpu = true; memory = true; }; }
      { resources = { label = "storage"; disk = [ "/data" ]; }; }
      {
        openmeteo = {
          label = "Calgary";
          timezone = "America/Edmonton";
          latitude = config.sops.secrets.homepage_latitude.path;
          longitude = config.sops.secrets.homepage_longitude.path;
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

  systemd.services.homepage-dashboard.environment = {
    HOMEPAGE_ALLOWED_HOSTS = lib.mkForce "localhost,127.0.0.1,192.168.1.165,home.labhome.work";
  };
}
