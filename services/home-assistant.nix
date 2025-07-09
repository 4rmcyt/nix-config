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
    configWritable = true;
    extraComponents = [
      "default_config"
      "mqtt"
      "http"
      "rokuecp"
    ];

    config = {
      homeassistant = {
        name = "Lab Home";
        unit_system = "metric";
        time_zone = "America/Edmonton";
        country = "CA";
        currency = "CAD";
        external_url = "https://home.example.com";
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