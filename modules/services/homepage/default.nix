{ pkgs, ... }:
{
  users.users.homepage-dashboard = {
    isSystemUser = true;
    group = "homepage-dashboard";
    extraGroups = [ "users" ];
  };
  users.groups.homepage-dashboard = { };

  networking.firewall.allowedTCPPorts = [
    8082 # Homepage Dashboard
  ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."home.labhome.work" = {
      forceSSL = true;
      sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
      sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
      locations."/" = {
        proxyPass = "http://localhost:8082";
      };
    };
  };

  environment.systemPackages = [ pkgs.homepage-dashboard ];

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
              widgets = [
                {
                  type = "jellyfin";
                  url = "http://localhost:8096";
                  key = "f719b5e954e94eac9bcd62e43c47fed4";
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
                  url = "http://localhost:9292";
                  key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXlJZCI6Ijk4ZWU0MDE1LWE5ZGQtNGY3ZS1hNjJiLWE0ZDMxMDkyODM0MCIsIm5hbWUiOiJIb21lcGFnZSIsInR5cGUiOiJhcGkiLCJpYXQiOjE3NTUyMTg3NzR9.OoImKplEpPhCVtIj-q_f9l6KjnnA0oKA_by2cOi2VaA";
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
              href = "https://sonnar.labhome.work/";
              widgets = [
                {
                  type = "sonarr";
                  url = "http://localhost:8989";
                  key = "7b5a494ab305456181bed6fab7d25b51";
                }
              ];
            };
          }
          {
            "Radarr" = {
              icon = "radarr.png";
              href = "https://radarr.labhome.work/";
              widgets = [
                {
                  type = "radarr";
                  url = "http://localhost:7878";
                  key = "47ebb17d25754575b43c654cc3af584e";
                }
              ];
            };
          }
          {
            "Transmission" = {
              icon = "transmission.png";
              href = "http://192.168.1.165:9091";
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
                  key = "7979f362842a4bbaa1de2d39d238ae3d";
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
                  key = "a5e3b4110b6a29d535099e678b02fc33";
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
                  key = "MTc1NTE4NDcxODI2NDdjMDU0ODk0LTQ4YWQtNDFkMS1iMjFkLWI1OGNjYzdhZTNmYg==";
                }
              ];
            };
          }
          {
            "Lidarr" = {
              icon = "lidarr.png";
              href = "https://lidarr.labhome.work/";
              widgets = [
                {
                  type = "lidarr";
                  url = "http://localhost:8686";
                  key = "1ab73c124aac4375b324a3014164781a";
                }
              ];
            };
          }
          {
            "Readarr" = {
              icon = "readarr.png";
              href = "https://readarr.labhome.work/";
              widgets = [
                {
                  type = "readarr";
                  url = "http://localhost:8787";
                  key = "acf29f1a3a74402b8fdeaa7308164145"; # optional
                }
              ];
            };
          }
          # {
          #   "Tdarr" = {
          #     href = "https://tdarr.labhome.work/";
          #     description = "Automated Transcoding";
          #     icon = "tdarr";
          #     widget = {
          #       type = "tdarr";
          #       url = "http://localhost:8266";
          #       key = "tdarrapikey"; # optional
          #     };
          #   };
          # }
        ];
      }
      {
        "Storage & Documents" = [
          {
            "Paperless" = {
              href = "https://paperless.labhome.work";
              description = "Document Management";
              icon = "paperless-ngx";
              widgets = [
                {
                  type = "paperlessngx";
                  url = "http://localhost:8888";
                  key = "77e2a8e18afcaa64a204441fe1c5c6a3a232e3d8";
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
                  key = "b26c4923-f105-4887-bfce-abf3a24c0794";
                }
              ];
            };
          }
        ];
      }
      {
        "Productivity Tools" = [
          {
            "Linkwarden" = {
              href = "http://192.168.1.165:3004";
              description = "Linkwarden Service";
              icon = "linkwarden";
              widgets = [
                {
                  type = "linkwarden";
                  url = "http://192.168.1.165:3004";
                  key = "linkwarden-api-key";
                }
              ];
            };
          }
          {
            "Miniflux" = {
              href = "https://miniflux.labhome.work";
              description = "RSS Reader";
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/miniflux.svg";
              widgets = [
                {
                  type = "miniflux";
                  url = "http://localhost:8086";
                  key = "5c9cccaaa0e1335a2e0e5ac0ac9995d2c60eb9c3086287bfddc9f74e5537079f";
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
      {
        "Monitoring & Analytics" = [
          {
            "Grafana" = {
              href = "https://grafana.labhome.work";
              description = "Real-time System Dashboard";
              icon = "grafana";
              widgets = [
                {
                  type = "grafana";
                  url = "http://localhost:3003";
                  username = "admin";
                  password = "Septuagint@1990";
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
          {
            "Uptime Kuma" = {
              href = "https://kuma.labhome.work";
              description = "Uptime Monitoring";
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/uptime-kuma.svg";
              widgets = [
                {
                  type = "uptimekuma";
                  url = "http://localhost:3001";
                  slug = "uk2_RbFIXIYfAeYVk-okhvOQBqw3IjnHB0zjzz4mkYfw";
                }
              ];
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
              icon = "https://cdn.jsdelivr.net/gh/selfhst/icons/svg/home-assistant.svg";
              widgets = [
                {
                  type = "homeassistant";
                  url = "https://hass.labhome.work";
                  key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJlOGFmM2RhMzY2N2I0ZDVlYWViYzc4Y2FhOGZmNGU4YiIsImlhdCI6MTc1MzM4MzA1MiwiZXhwIjoyMDY4NzQzMDUyfQ.S4p_4-V2weR99zTtvSAtrB-9yTze9_yQCut1Q50Uuu4";
                }
              ];
            };
          }
          {
            "Mosquito MQTT" = {
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
            "Authentik" = {
              href = "https://auth.labhome.work";
              description = "Identity & Access Management";
              icon = "authentik";
              widget = {
                type = "authentik";
                url = "https://auth.labhome.work";
                key = "VL3AR8dWq1VIVb4VIGdupq8bRMIQ32YoGzCrqnb7D6X3R6e2KOn1m6aWQjrz";
              };
            };
          }
          {
            "NextDns" = {
              href = "https://my.nextdns.io/";
              description = "Nextdns Dashboard";
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/nextdns.svg";
              widget = {
                type = "nextdns";
                profile = "2bffa2";
                key = "a6961bc6da99dc4335c98263706c963eceed39ef";
              };
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
                  deviceid = "njShKixPvA21CNTRL";
                  key = "tskey-api-k75wJ2z2qD11CNTRL-PajmXo4dB71YsoV2kyZo71Quv2rQkgi4B";
                }
              ];
            };
          }
          {
            "Cloudflare Tunnels" = {
              href = "https://one.dash.cloudflare.com/8239dd1bb0d0bfedf13673a195df59cf/networks/tunnels";
              description = "Cloudflare Tunnels Management";
              icon = "cloudflare-zero-trust";
              widgets = [
                {
                  type = "cloudflared";
                  accountid = "8239dd1bb0d0bfedf13673a195df59cf";
                  tunnelid = "f7876e26-87a8-4bdd-9798-3986b0f7cebc";
                  key = "yMAEOHdD1sDxrw9tLbu-QRKmn2SftHVx2Q8Cj3j9";
                }
              ];
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
          latitude = "51.043674";
          longitude = "-114.09521";
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
  systemd.services.homepage-dashboard.serviceConfig = {
    Environment = [
      "HOMEPAGE_ALLOWED_HOSTS=localhost,127.0.0.1,192.168.1.165,home.labhome.work"
    ];
  };
}
