{ config, pkgs, ... }:

{
  services.home-assistant = {
    enable = true;
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
    ];
    
    config = {
      default_config = {};
      
      homeassistant = {
        name = "Home";
        latitude = 32.0853;
        longitude = 34.7818;
        elevation = 10;
        unit_system = "metric";
        time_zone = "Asia/Jerusalem";
      };
      
      http = {
        server_port = 8123;
        # Cloudflare Tunnel direct access
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
          # Add Cloudflare IP ranges
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
      
      frontend = {};
      config = {};
      history = {};
      logbook = {};
      system_health = {};
      energy = {};
    };
  };

  users.users.hass.extraGroups = [ "dialout" ];

  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zigbee", GROUP="dialout", MODE="0660"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", SYMLINK+="zigbee", GROUP="dialout", MODE="0660"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0658", ATTRS{idProduct}=="0200", SYMLINK+="zwave", GROUP="dialout", MODE="0660"
  '';
}