# /etc/nixos/services/homepage.nix

{ config, pkgs, lib, ... }:

{
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;

    # All environment variables, including secrets, are defined here as strings.
    environment = {
      HOMEPAGE_ALLOWED_HOSTS = "localhost,127.0.0.1,192.168.1.165,home.labhome.work";
      HOMEPAGE_VAR_JELLYSEERR_KEY = "MTc1MzI0Mzg5OTUwN2M2YmRjZmU5LWI1YzktNDMwMi1iNDAzLTlhMzY0NDdjMzdiYQ==";
      HOMEPAGE_VAR_LIDARR_KEY = "64667f73a2874bcc9b2cd64827ae06a6";
      HOMEPAGE_VAR_PROWLARR_KEY = "9d24bc9a25174e9cab035094b085c13c";
      HOMEPAGE_VAR_RADARR_KEY = "035416a4da9f4dbd8cd74783b92a607d";
      HOMEPAGE_VAR_READARR_KEY = "ff9911f318764d23a06635cca79e1e7a";
      HOMEPAGE_VAR_READARR_AUDIOBOOKS_KEY = "5aad134f8e714f30bd4d98cbbb6cafd1";
      HOMEPAGE_VAR_SONARR_KEY = "96661495dcac4fbb90e7b01ede2f1b36";
      HOMEPAGE_VAR_BAZARR_KEY = "ec02b57b195afb25c73b89df7802af82";
      HOMEPAGE_VAR_PAPERLESS_KEY = "77e2a8e18afcaa64a204441fe1c5c6a3a232e3d8";
      HOMEPAGE_VAR_MINIFLUX_KEY = ""; # Set to empty string from null
      HOMEPAGE_VAR_TAILSCALE_KEY = "tskey-api-kcY19LgP3m11CNTRL-G369y5gJfz8T82PxZ5GH19AvFC1wvHVS1";
      HOMEPAGE_VAR_TAILSCALE_DEVICE_ID = "nXJkpdBaD611CNTRL";
      HOMEPAGE_VAR_CLOUDFLARED_ACCOUNT_ID = "8239dd1bb0d0bfedf13673a195df59cf";
      HOMEPAGE_VAR_CLOUDFLARED_KEY = "yMAEOHdD1sDxrw9tLbu-QRKmn2SftHVx2Q8Cj3j9";
      HOMEPAGE_VAR_CLOUDFLARED_TUNNEL_ID = "f7876e26-87a8-4bdd-9798-3986b0f7cebc";
      HOMEPAGE_VAR_GRAFANA_ADMIN_PASSWORD = "Septuagint@1990";
      HOMEPAGE_VAR_JELLYFIN_KEY = "MTc1MzI0Mzg5OTUwN2M2YmRjZmU5LWI1YzktNDMwMi1iNDAzLTlhMzY0NDdjMzdiYQ==";
      HOMEPAGE_VAR_AUDIOBOOKSHELF_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXlJZCI6ImNkMjUwZDE4LTg3ZmEtNGRkMC1iNDc0LTQ0ZDFlYzliN2Y5MCIsIm5hbWUiOiJob21lcGFnZSIsInR5cGUiOiJhcGkiLCJpYXQiOjE3NTMyNDY4OTB9.ZciPaGs_zxUF7axHQTk0eSelSEvLoF7OO8f2";
      HOMEPAGE_VAR_KAVITA_KEY = "vdi6CWjzI1zSxFovJnwhO4wWQcbWErSWqhZ9N7OhSc71Ahv5bEL7vkU1K6QwJ600gL7jZ2HDALC3jODa3B4OtQ==";
      HOMEPAGE_VAR_LATITUDE = "51.043674";
      HOMEPAGE_VAR_LONGITUDE = "-114.09521";
      HOMEPAGE_VAR_HASS_KEY = "eeyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJkNjVmNDg4OWRiODE0MTFjYWU5YjBiZDAxZDM5NjEwMiIsImlhdCI6MTc1MzEyNzI3OCwiZXhwIjoyMDY4NDg3Mjc4fQ.GlLvDuYh8DctiNa6O00zUzRFJw9n6SycmcuPbK8yjjM";
    };

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
                url = "http://localhost:9292";
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
              href = "https://sonnar.labhome.work/";
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
              href = "https://radarr.labhome.work/";
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
          {
            "Readarr-Audiobooks" = {
              icon = "readarr.png";
              href = "https://readarr-audiobook.labhome.work/";
              widgets = [{
                type = "readarr";
                url = "http://localhost:9494";
                key = "{{HOMEPAGE_VAR_READARR_AUDIOBOOKS_KEY}}";
              }];
            };
          }
        ];
      }
      {
        "Storage & Documents" = [
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
            "Tailscale" = {
              href = "https://login.tailscale.com/admin/machines";
              description = "Mesh VPN Administration";
              icon = "tailscale";
              widgets = [{
                type = "tailscale";
                deviceid = "{{HOMEPAGE_VAR_TAILSCALE_DEVICE_ID}}";
                key = "{{HOMEPAGE_VAR_TAILSCALE_KEY}}";
              }];
            };
          }
          {
            "Cloudflare Tunnels" = {
              href = "https://one.dash.cloudflare.com/8239dd1bb0d0bfedf13673a195df59cf/networks/tunnels";
              description = "Cloudflare Tunnels Management";
              icon = "cloudflare-zero-trust";
              widgets = [{
                type = "cloudflared";
                accountid = "{{HOMEPAGE_VAR_CLOUDFLARED_ACCOUNT_ID}}";
                tunnelid = "{{HOMEPAGE_VAR_CLOUDFLARED_TUNNEL_ID}}";
                key = "{{HOMEPAGE_VAR_CLOUDFLARED_KEY}}";
              }];
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
}