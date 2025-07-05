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
      # Core integrations
      "default_config"
      "met"
      "radio_browser"

      # Network & Communication
      "mqtt"
      "http"
      "websocket_api"
      "mobile_app"

      # Media & Entertainment
      "media_player"
      "cast"
      "spotify"

      # Smart Home Protocols
      "zha"
      "zwave_js"
      "esphome"
      "tasmota"

      # Sensors & Monitoring
      "sensor"
      "binary_sensor"
      "template"
      "history"
      "logbook"
      "recorder"

      # Automation & Scripts
      "automation"
      "script"
      "scene"
      "input_boolean"
      "input_number"
      "input_select"
      "input_text"
      "input_datetime"

      # Security & Access
      "person"
      "device_tracker"
      "zone"

      # Weather & Location
      "sun"
      "weather"

      # File Management
      "file_upload"

      # Energy Management
      "energy"

      # Shopping & Lists
      "shopping_list"

      # Calendar
      "calendar"

      # System Health
      "system_health"
      "logger"
    ];

    extraPackages = python3Packages: with python3Packages; [
      # Database drivers
      psycopg2

      # MQTT support
      paho-mqtt

      # Additional protocols
      pyserial
      pyusb

      # Media support
      pillow

      # Network tools
      requests
      aiohttp

      # Encryption & Security
      cryptography

      # Data processing
      numpy

      # Time & Date handling
      python-dateutil
    ];

    config = {
      # Basic configuration
      homeassistant = {
        name = "Lab Home";
        latitude = "!secret latitude";
        longitude = "!secret longitude";
        elevation = "!secret elevation";
        unit_system = "metric";
        time_zone = "America/Edmonton";
        country = "CA";
        currency = "CAD";

        # External access configuration
        external_url = "https://home.example.com";
        internal_url = "http://192.168.1.165:8123";

        # Allow embedding in iframe (for homepage dashboard)
        allowlist_external_dirs = [
          "/home/hass/.homeassistant"
          "/var/lib/hass"
        ];
      };

      # HTTP configuration for reverse proxy
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

      # Database configuration (PostgreSQL)
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

      # MQTT configuration
      mqtt = {
        broker = "192.168.1.165";
        port = 1883;
        username = "iotdevice";
        password = "!secret mqtt_password";
        discovery = true;
        discovery_prefix = "homeassistant";
      };

      # Enable default integrations
      default_config = {};

      # Frontend configuration
      frontend = {
        themes = "!include_dir_merge_named themes";
      };

      # Enable the shopping list
      shopping_list = {};

      # Enable the map
      map = {};

      # Enable system health checks
      system_health = {};

      # Logger configuration
      logger = {
        default = "info";
        logs = {
          "homeassistant.core" = "debug";
          "homeassistant.components.mqtt" = "debug";
        };
      };
    };
  };

  # PostgreSQL database for Home Assistant
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "hass" ];
    ensureUsers = [
      {
        name = "hass";
        ensureDBOwnership = true;
      }
    ];
  };

  # Set up the hass user password
  systemd.services.postgresql.postStart = ''
    $PSQL -tA <<'EOF'
      ALTER ROLE hass WITH PASSWORD '$(cat ${config.sops.secrets.hass_postgres_password.path})';
    EOF
  '';

  # REMOVED: Firewall port (now handled centrally in networking.nix)
}