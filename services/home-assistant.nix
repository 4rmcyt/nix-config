{ config, pkgs, lib, ... }:

{
  # SOPS secrets for Home Assistant
  sops.secrets.hass_postgres_password = {
    owner = "hass";
    group = "hass";
    mode = "0400";
  };

  services.home-assistant = {
    enable = true;
    extraComponents = [
      "default_config"
      "mqtt"
      "http"
      "websocket_api"
      "mobile_app"
      "media_player"
      "cast"
      "spotify"
      "zha"
      "zwave_js"
      "esphome"
      "tasmota"
      "sensor"
      "binary_sensor"
      "template"
      "history"
      "logbook"
      "recorder"
      "automation"
      "script"
      "scene"
      "input_boolean"
      "input_number"
      "input_select"
      "input_text"
      "input_datetime"
      "person"
      "device_tracker"
      "zone"
      "sun"
      "weather"
      "file_upload"
      "energy"
      "shopping_list"
      "calendar"
      "system_health"
      "logger"
    ];

    extraPackages = python3Packages: with python3Packages; [
      # Database drivers
      psycopg2
      # MQTT support
      paho-mqtt
      pyserial
      pyusb
      pillow
      requests
      aiohttp
      cryptography
      numpy
      python-dateutil
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
        exclude = {
          domains = [
            "automation"
            "updater"
            "camera"
          ];
          entities = [
            "sun.sun"
            "sensor.date"
            "sensor.time"
          ];
        };
        purge_keep_days = 30;
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
}