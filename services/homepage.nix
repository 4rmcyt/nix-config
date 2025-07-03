{ config, pkgs, ... }:

{
  services.homepage-dashboard = {
    enable = true;
    
    settings = {
      title = "Homeserver Dashboard";
      
      layout = {
        "Media" = {
          style = "row";
          columns = 2;
        };
        "Home Automation" = {
          style = "row";
          columns = 2;
        };
        "Productivity" = {
          style = "row";
          columns = 3;
        };
        "System" = {
          style = "row";
          columns = 2;
        };
      };
    };
    
    # Services configuration
    services = [
      {
        "Media" = [
          {
            "Jellyfin" = {
              icon = "jellyfin";
              href = "https://jellyfin.labhome.work";
              description = "Media streaming server";
              widget = {
                type = "jellyfin";
                url = "http://localhost:8096";
                key = "your-jellyfin-api-key";
              };
            };
          }
          {
            "Deluge" = {
              icon = "deluge";
              href = "https://deluge.labhome.work";
              description = "BitTorrent client";
              widget = {
                type = "deluge";
                url = "http://localhost:8112";
                password = "deluge";
              };
            };
          }
        ];
      }
      {
        "Home Automation" = [
          {
            "Home Assistant" = {
              icon = "home-assistant";
              href = "https://home.labhome.work";
              description = "Home automation platform";
              widget = {
                type = "homeassistant";
                url = "http://localhost:8123";
                key = "your-ha-token";
              };
            };
          }
        ];
      }
      {
        "Productivity" = [
          {
            "Nextcloud" = {
              icon = "nextcloud";
              href = "https://nextcloud.labhome.work";
              description = "Personal cloud storage";
              widget = {
                type = "nextcloud";
                url = "http://localhost:8081";
                username = "admin";
                password = "your-password";
              };
            };
          }
          {
            "Paperless" = {
              icon = "paperless";
              href = "https://paperless.labhome.work";
              description = "Document management";
              widget = {
                type = "paperlessngx";
                url = "http://localhost:8082";
                key = "your-paperless-token";
              };
            };
          }
          {
            "Miniflux" = {
              icon = "miniflux";
              href = "https://rss.labhome.work";
              description = "RSS reader";
              widget = {
                type = "miniflux";
                url = "http://localhost:8083";
                username = "admin";
                password = "your-miniflux-password";
              };
            };
          }
        ];
      }
      {
        "System" = [
          {
            "Keycloak" = {
              icon = "keycloak";
              href = "https://keycloak.labhome.work";
              description = "Identity and access management";
            };
          }
          {
            "Radicale" = {
              icon = "radicale";
              href = "https://cal.labhome.work";
              description = "CalDAV and CardDAV server";
            };
          }
        ];
      }
    ];
    
    widgets = [
      {
        logo = {
          icon = "https://cdn.jsdelivr.net/gh/walkxcode/dashboard-icons/png/homepage.png";
        };
      }
      {
        search = {
          provider = "duckduckgo";
          target = "_blank";
        };
      }
      {
        datetime = {
          text_size = "xl";
          format = {
            timeStyle = "short";
            dateStyle = "short";
            hourCycle = "h23";
          };
        };
      }
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
          uptime = true;
        };
      }
    ];
    
    bookmarks = [
      {
        "Developer" = [
          {
            "Github" = [
              {
                abbr = "GH";
                href = "https://github.com/";
              }
            ];
          }
        ];
      }
      {
        "Social" = [
          {
            "Reddit" = [
              {
                abbr = "RE";
                href = "https://reddit.com/";
              }
            ];
          }
        ];
      }
    ];
  };

  # Remove firewall config - handled centrally in networking.nix
}