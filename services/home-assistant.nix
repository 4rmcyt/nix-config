{
  config,
  pkgs,
  lib,
  ...
}:

{ 
  environment.systemPackages = with pkgs; [
    home-assistant
    mosquitto
    psycopg2
    pyatv
  ];

  services = {
    home-assistant = {
      enable = true;
      configDir = "/var/lib/home-assistant";
      configWritable = true;
      # This block has been rewritten to be more explicit and correct
      extraPackages = ps: [
        ps.psycopg2
        ps.pyatv
      ];
      extraComponents = [
        "mqtt"
        "http"
        "roku"
        "alexa_devices"
        "upnp"
        "radio_browser"
        "met"
        "paperless_ngx"
        "playstation_network"
        "jellyfin"
      ];

      config = {
        homeassistant = {
          name = "Lab Home";
          unit_system = "metric";
          time_zone = "America/Edmonton";
          country = "CA";
          currency = "CAD";
          external_url = "https://hass.labhome.work";
          internal_url = "http://192.168.1.165:8123";
        };

        config.recorder.db_url = "postgresql://@/hass";
        
        http = {
          server_host = "0.0.0.0";
          server_port = 8123;
          use_x_forwarded_for = true;
          trusted_proxies = [
            "127.0.0.1"
            "192.168.1.165"
          ];
          ip_ban_enabled = true;
          login_attempts_threshold = 5;
        };

        tts = [
          {
            platform = "google_translate";
            language = "en";
          }
        ];

        mqtt = { };

        default_config = { };

        frontend = {
          themes = "!include_dir_merge_named themes";
        };

        shopping_list = { };
        map = { };
        system_health = { };

        logger = {
          default = "info";
          logs = {
            "homeassistant.core" = "debug";
          };
        };
      };
    };

    mosquitto = {
      enable = true;
      listeners = [
        {
          # This allows anonymous connections on this listener
          settings.allow_anonymous = true;
          users = {
            root = {
              acl = [ "readwrite #" ];
            };
          };
        }
      ];
    };
  };
  users.users.hass = {
    isSystemUser = true;
    group = "hass";
  };
  users.users.mosquitto = {
    isSystemUser = true;
    group = "mosquitto";
  };
  users.groups.mosquitto = {};
  users.groups.hass = {};
}
