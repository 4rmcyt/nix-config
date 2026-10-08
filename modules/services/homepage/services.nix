{config}: [
  {
    Media = [
      {
        Jellyfin = {
          icon = "jellyfin.png";
          href = "{{HOMEPAGE_VAR_JELLYFIN_URL}}";
          description = "Media Server";
          widget = {
            type = "jellyfin";
            url = "{{HOMEPAGE_VAR_JELLYFIN_INTERNAL_URL}}";
            key = "{{HOMEPAGE_VAR_JELLYFIN_API_KEY}}";
            version = 2;
          };
        };
      }
      {
        Audiobookshelf = {
          icon = "audiobookshelf.png";
          href = "{{HOMEPAGE_VAR_AUDIOBOOKSHELF_URL}}";
          description = "Audiobooks & Podcasts";
          widget = {
            type = "audiobookshelf";
            url = "{{HOMEPAGE_VAR_AUDIOBOOKSHELF_INTERNAL_URL}}";
            key = "{{HOMEPAGE_VAR_AUDIOBOOKSHELF_API_KEY}}";
          };
        };
      }
      {
        Komga = {
          icon = "komga.png";
          href = "{{HOMEPAGE_VAR_KOMGA_URL}}";
          description = "Comics & Manga Library";
          widget = {
            type = "komga";
            url = "{{HOMEPAGE_VAR_KOMGA_INTERNAL_URL}}";
            username = "{{HOMEPAGE_VAR_KOMGA_USERNAME}}";
            password = "{{HOMEPAGE_VAR_KOMGA_PASSWORD}}";
          };
        };
      }
    ];
  }
  {
    Downloads = [
      {
        qBittorrent = {
          icon = "qbittorrent.png";
          href = "{{HOMEPAGE_VAR_QBITTORRENT_URL}}";
          description = "Torrent Client";
          widget = {
            type = "qbittorrent";
            url = "{{HOMEPAGE_VAR_QBITTORRENT_URL}}";
          };
        };
      }
      {
        Sonarr = {
          icon = "sonarr.png";
          href = "{{HOMEPAGE_VAR_SONARR_URL}}";
          description = "TV Series";
          widget = {
            type = "sonarr";
            url = "{{HOMEPAGE_VAR_SONARR_INTERNAL_URL}}";
            key = "{{HOMEPAGE_VAR_SONARR_API_KEY}}";
          };
        };
      }
      {
        Radarr = {
          icon = "radarr.png";
          href = "{{HOMEPAGE_VAR_RADARR_URL}}";
          description = "Movies";
          widget = {
            type = "radarr";
            url = "{{HOMEPAGE_VAR_RADARR_INTERNAL_URL}}";
            key = "{{HOMEPAGE_VAR_RADARR_API_KEY}}";
          };
        };
      }
      {
        Lidarr = {
          icon = "lidarr.png";
          href = "{{HOMEPAGE_VAR_LIDARR_URL}}";
          description = "Music";
          widget = {
            type = "lidarr";
            url = "{{HOMEPAGE_VAR_LIDARR_INTERNAL_URL}}";
            key = "{{HOMEPAGE_VAR_LIDARR_API_KEY}}";
          };
        };
      }
      {
        Prowlarr = {
          icon = "prowlarr.png";
          href = "{{HOMEPAGE_VAR_PROWLARR_URL}}";
          description = "Indexer Manager";
          widget = {
            type = "prowlarr";
            url = "{{HOMEPAGE_VAR_PROWLARR_INTERNAL_URL}}";
            key = "{{HOMEPAGE_VAR_PROWLARR_API_KEY}}";
          };
        };
      }
      {
        Bazarr = {
          icon = "bazarr.png";
          href = "{{HOMEPAGE_VAR_BAZARR_URL}}";
          description = "Subtitles";
          widget = {
            type = "bazarr";
            url = "{{HOMEPAGE_VAR_BAZARR_INTERNAL_URL}}";
            key = "{{HOMEPAGE_VAR_BAZARR_API_KEY}}";
          };
        };
      }
      {
        Kapowarr = {
          icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/kapowarr.png";
          href = "{{HOMEPAGE_VAR_KAPOWARR_URL}}";
          description = "Comics & Manga Downloader";
        };
      }
      {
        Seerr = {
          icon = "seerr.png";
          href = "{{HOMEPAGE_VAR_SEERR_URL}}";
          description = "Media Requests";
          widget = {
            type = "seerr";
            url = "{{HOMEPAGE_VAR_SEERR_INTERNAL_URL}}";
            key = "{{HOMEPAGE_VAR_SEERR_API_KEY}}";
          };
        };
      }
      {
        Shelfmark = {
          icon = "shelfmark.png";
          href = "https://shelfmark.${config.my.defaults.domain}";
          description = "Books";
        };
      }
    ];
  }
  {
    "Smart Home" = [
      {
        "Home Assistant" = {
          icon = "home-assistant.png";
          href = "{{HOMEPAGE_VAR_HASS_URL}}";
          description = "Home Automation";
          widget = {
            type = "homeassistant";
            url = "{{HOMEPAGE_VAR_HASS_INTERNAL_URL}}";
            key = "{{HOMEPAGE_VAR_HASS_API_KEY}}";
            fields = [
              "people_home"
              "lights_on"
              "switches_on"
            ];
          };
        };
      }
    ];
  }
  {
    Productivity = [
      {
        Miniflux = {
          icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/miniflux.svg";
          href = "{{HOMEPAGE_VAR_MINIFLUX_URL}}";
          description = "RSS Reader";
          widget = {
            type = "miniflux";
            url = "{{HOMEPAGE_VAR_MINIFLUX_INTERNAL_URL}}";
            key = "{{HOMEPAGE_VAR_MINIFLUX_API_KEY}}";
          };
        };
      }
      {
        Radicale = {
          icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/radicale.png";
          href = "{{HOMEPAGE_VAR_RADICALE_URL}}";
          description = "CalDAV & CardDAV";
          siteMonitor = "{{HOMEPAGE_VAR_RADICALE_URL}}";
        };
      }
      {
        Ntfy = {
          icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/ntfy.png";
          href = "{{HOMEPAGE_VAR_NTFY_URL}}";
          description = "Push Notifications";
        };
      }
      {
        Microbin = {
          icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/microbin.png";
          href = "{{HOMEPAGE_VAR_MICROBIN_URL}}";
          description = "Paste Bin";
        };
      }
    ];
  }
  {
    Calendar = [
      {
        Calendar = {
          widget = {
            type = "calendar";
            firstDayInWeek = "monday";
            view = "monthly";
            maxEvents = 10;
            showTime = true;
            integrations = [
              {
                type = "sonarr";
                service_group = "Downloads";
                service_name = "Sonarr";
                color = "teal";
              }
              {
                type = "radarr";
                service_group = "Downloads";
                service_name = "Radarr";
                color = "yellow";
              }
              {
                type = "lidarr";
                service_group = "Downloads";
                service_name = "Lidarr";
                color = "green";
              }
            ];
          };
        };
      }
      {
        Agenda = {
          widget = {
            type = "calendar";
            view = "agenda";
            maxEvents = 10;
            showTime = true;
            previousDays = 1;
            integrations = [
              {
                type = "sonarr";
                service_group = "Downloads";
                service_name = "Sonarr";
                color = "teal";
              }
              {
                type = "radarr";
                service_group = "Downloads";
                service_name = "Radarr";
                color = "yellow";
              }
              {
                type = "lidarr";
                service_group = "Downloads";
                service_name = "Lidarr";
                color = "green";
              }
            ];
          };
        };
      }
    ];
  }
  {
    "Monitoring & Analytics" = [
      {
        Grafana = {
          icon = "grafana.png";
          href = "{{HOMEPAGE_VAR_GRAFANA_URL}}";
          description = "System Dashboards";
          widget = {
            type = "grafana";
            url = "{{HOMEPAGE_VAR_GRAFANA_INTERNAL_URL}}";
            username = "{{HOMEPAGE_VAR_GRAFANA_USERNAME}}";
            password = "{{HOMEPAGE_VAR_GRAFANA_PASSWORD}}";
            version = 2;
          };
        };
      }
      {
        Caddy = {
          icon = "caddy.png";
          # No built-in UI; link to the provisioned Grafana dashboard.
          href = "{{HOMEPAGE_VAR_GRAFANA_URL}}/d/caddy-homeserver";
          description = "Reverse Proxy";
          widget = {
            type = "caddy";
            url = "http://localhost:${toString config.my.network.ports.caddy-admin}";
          };
        };
      }
      {
        CrowdSec = {
          icon = "crowdsec.png";
          description = "Threat Intelligence";
          # Native crowdsec widget hardcodes include_capi=false, so the community blocklist never shows; read Prometheus instead.
          widget = {
            type = "prometheusmetric";
            url = "http://localhost:${toString config.my.network.ports.prometheus}";
            metrics = [
              {
                label = "Blocklist";
                query = ''sum(cs_active_decisions{origin="CAPI"}) or vector(0)'';
                format.type = "number";
              }
              {
                label = "Own bans";
                query = ''sum(cs_active_decisions{origin!="CAPI"}) or vector(0)'';
                format.type = "number";
              }
              {
                label = "WAF 24h";
                query = "sum(increase(cs_appsec_block_total[24h])) or vector(0)";
                format = {
                  type = "number";
                  options.maximumFractionDigits = 0;
                };
              }
            ];
          };
        };
      }
      {
        NextDns = {
          icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/nextdns.svg";
          href = "{{HOMEPAGE_VAR_NEXTDNS_URL}}";
          description = "DNS Filtering";
        };
      }
    ];
  }
]
