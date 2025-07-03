{ config, pkgs, ... }:

{
  # SOPS secret for Home Assistant database
  sops.secrets.hass_postgres_password = {
    owner = "hass";
    group = "hass";
  };

  services.home-assistant = {
    enable = true;
    
    # Add PostgreSQL support
    package = pkgs.home-assistant.override {
      extraPackages = ps: with ps; [
        psycopg2  # PostgreSQL driver
        # Add other packages if needed
      ];
    };
    
    extraComponents = [
      "default_config"
      "met"
      "radio_browser"
      "shopping_list"
      "systemmonitor"
      "zha"
      "zwave_js"
      "esphome"
      "mqtt"
      "spotify"
      "cast"
      "media_player"
      "telegram_bot"
      "mobile_app"
      "openweathermap"
      "person"
      "device_tracker"
      "zone"
      "recorder"  # Add recorder explicitly
    ];
    
    config = {
      default_config = {};
      
      homeassistant = {
        name = "Home";
        latitude = 32.0853;
        longitude = 34.7818;
        elevation = 10;
        unit_system = "metric";
        time_zone = "America/Edmonton";
      };
      
      # Fixed HTTP configuration
      http = {
        server_port = 8123;
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
          # Cloudflare IP ranges
          "173.245.48.0/20"
          "103.21.244.0/22"
          "103.22.200.0/22"
          "103.31.4.0/22"
          "141.101.64.0/18"
          "108.162.192.0/18"
          "190.93.240.0/20"
          "188.114.96.0/20"
          "197.234.240.0/22"
          "198.41.128.0/17"
          "162.158.0.0/15"
          "104.16.0.0/13"
          "104.24.0.0/14"
          "172.64.0.0/13"
          "131.0.72.0/22"
        ];
        ip_ban_enabled = true;
        login_attempts_threshold = 5;
      };
      
      # Database configuration for PostgreSQL
      recorder = {
        db_url = "postgresql://hass:!secret db_password@localhost/hass";
        purge_keep_days = 10;
        auto_purge = true;
        exclude = {
          domains = [
            "automation"
            "updater"
          ];
          entity_globs = [
            "sensor.*_battery"
            "sensor.*_temperature"
          ];
        };
      };
      
      frontend = {};
      config = {};
      history = {};
      logbook = {};
      system_health = {};
      energy = {};
    };
  };

  # Add hass user to dialout group for USB devices
  users.users.hass.extraGroups = [ "dialout" ];

  # USB device rules for Zigbee and Z-Wave
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zigbee", GROUP="dialout", MODE="0660"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", SYMLINK+="zigbee", GROUP="dialout", MODE="0660"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0658", ATTRS{idProduct}=="0200", SYMLINK+="zwave", GROUP="dialout", MODE="0660"
  '';

  # Open firewall port
  networking.firewall.allowedTCPPorts = [ 8123 ];
}
