[
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
      {
        Dispatcharr = {
          icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/dispatcharr.png";
          href = "{{HOMEPAGE_VAR_DISPATCHARR_URL}}";
          description = "IPTV Stream Manager";
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
        LazyLibrarian = {
          icon = "lazylibrarian.png";
          href = "{{HOMEPAGE_VAR_LAZYLIBRARIAN_URL}}";
          description = "Books";
          widget = {
            type = "customapi";
            url = "{{HOMEPAGE_VAR_LAZYLIBRARIAN_INTERNAL_URL}}/api?cmd=showstats&apikey={{HOMEPAGE_VAR_LAZYLIBRARIAN_API_KEY}}";
            mappings = [
              {
                label = "Books Wanted";
                field = {book_stats = "Wanted";};
              }
              {
                label = "Books Snatched";
                field = {book_stats = "Snatched";};
              }
            ];
          };
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
        Traefik = {
          icon = "traefik.png";
          href = "{{HOMEPAGE_VAR_TRAEFIK_URL}}";
          description = "Reverse Proxy";
          widget = {
            type = "traefik";
            url = "{{HOMEPAGE_VAR_TRAEFIK_INTERNAL_URL}}";
          };
        };
      }
      {
        CrowdSec = {
          icon = "crowdsec.png";
          description = "Threat Intelligence";
          widget = {
            type = "crowdsec";
            url = "{{HOMEPAGE_VAR_CROWDSEC_INTERNAL_URL}}";
            username = "{{HOMEPAGE_VAR_CROWDSEC_USERNAME}}";
            password = "{{HOMEPAGE_VAR_CROWDSEC_PASSWORD}}";
          };
        };
      }
      {
        NextDns = {
          icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/nextdns.svg";
          href = "{{HOMEPAGE_VAR_NEXTDNS_URL}}";
          description = "DNS Filtering";
          widget = {
            type = "nextdns";
            profile = "{{HOMEPAGE_VAR_NEXTDNS_PROFILE}}";
            key = "{{HOMEPAGE_VAR_NEXTDNS_API_KEY}}";
          };
        };
      }
    ];
  }
]
