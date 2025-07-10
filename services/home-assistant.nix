{ config, pkgs, lib, ... }:

{
  # SOPS secrets for Home Assistant
  sops.secrets.hass_postgres_password = {
    owner = "hass";
    group = "hass";
    mode = "0400";
  };
  
  services = {
    home-assistant = {
    enable = true;
    package = (unstable.home-assistant.overrideAttrs (old: {
      doCheck = false;
      checkPhase = ":";
      installCheckPhase = ":";
    })).override {
      extraPackages = ps: with ps; [
        python-forecastio jsonrpc-async jsonrpc-websocket mpd2 pkgs.picotts psycopg2
      ];
    };
    configDir = "/var/lib/home-assistant";
    configWritable = true;
    extraComponents = [
      "default_config"
      "mqtt"
      "http"
      "roku"
      "alexa"
      "alexa_devices"
    ];

      config = {
        homeassistant = {
          name = "Lab Home";
          unit_system = "metric";
          time_zone = "America/Edmonton";
          country = "CA";
          currency = "CAD";
          external_url = "https://home.labhome.work";
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

        # PostgreSQL configuration
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
            base_url = "https://hasss.labhome.work";
            language = "en";
            time_memory = 57600;
            service_name =  "google_say";
          }
        ];
        
        mqtt = {
          broker = "localhost";
          discovery = true;
          discovery_prefix = "homeassistant";
          username = "hass";
          password = config.sops.secrets.mosquitto_iotdevice_password.path;
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
          address = "0.0.0.0";
          users = {
            hass = {
              acl = [ "topic readwrite #" ];
              password = config.sops.secrets.mosquitto_iotdevice_password.path;
            };
          };
        }
      ];
    };
  };
}