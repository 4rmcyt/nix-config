{ config, pkgs, lib, ... }:

{
  # SOPS secrets for Home Assistant
  sops.secrets.hass_postgres_password = {
    owner = "hass";
    group = "hass";
    mode = "0400";
  };

  sops.secrets.mosquitto_iotdevice_password = {
    owner = "mqtt";
    group = "mqtt";
    mode = "444";
  };

  services = {
    home-assistant = {
      enable = true;
      configDir = "/var/lib/home-assistant";
      configWritable = true;
      # This block has been rewritten to be more explicit and correct
      extraPackages =
          python3Packages: with python3Packages; [
            psycopg2
            pyatv
          ];
      extraComponents = [
        "mqtt"
        "http"
        "roku"
        "alexa_devices"
        "upnp"
        "radio_browser"
        "met"
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

        recorder = {
          db_url = "postgresql://hass:$(cat ${config.sops.secrets.hass_postgres_password.path})@localhost/hass";
          include = {
            domains = [
              "switch"
              "sensor"
              "binary_sensor"
            ];
          };
          purge_keep_days = 30;
        };

        tts = [
          { platform = "google_translate";
            cache = true;
            cache_dir = "/tmp/tts";
            base_url = "https://hass.labhome.work";
            language = "en";
            time_memory = 57600;
            service_name =  "google_say";
          }
        ];

        mqtt = {
          broker = "localhost";
          discovery = true;
          discovery_prefix = "homeassistant";
        };

        default_config = {};

        frontend = {
          themes = "!include_dir_merge_named themes";
        };

        shopping_list = {};
        map = {};
        system_health = {};

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
              passwordFile = config.sops.secrets.mosquitto_iotdevice_password.path;
            };
          };
        }
      ];
    };
  };
}
