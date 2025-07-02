{ config, pkgs, ... }:

{
  services.home-assistant = {
    enable = true;
    extraComponents = [
      # Core integrations
      "default_config"
      "met"
      "radio_browser"
      "shopping_list"
      "systemmonitor"
      
      # Hardware integrations
      "zha"
      "zwave_js"
      "esphome"
      "mqtt"
      
      # Media
      "spotify"
      "cast"
      "media_player"
      
      # Notifications
      "telegram_bot"
      "mobile_app"
      
      # Weather
      "openweathermap"
      
      # Security
      "person"
      "device_tracker"
      "zone"
    ];
    
    config = {
      default_config = {};
      
      homeassistant = {
        name = "Home";
        latitude = 32.0853;  # Replace with your coordinates
        longitude = 34.7818;
        elevation = 10;
        unit_system = "metric";
        time_zone = "Asia/Jerusalem";  # Replace with your timezone
      };
      
      http = {
        server_port = 8123;
        use_x_forwarded_for = true;
        trusted_proxies = [ "127.0.0.1" ];
      };
      
      # Enable the frontend
      frontend = {};
      
      # Enable configuration UI
      config = {};
      
      # Enable history
      history = {};
      
      # Enable logbook
      logbook = {};
      
      # Enable system health
      system_health = {};
      
      # Enable energy management
      energy = {};
    };
  };

  # Add hass user to dialout group for USB devices (like Zigbee sticks)
  users.users.hass.extraGroups = [ "dialout" ];

  # Open firewall port for Home Assistant
  networking.firewall.allowedTCPPorts = [ 8123 ];

  # Enable USB access for Zigbee/Z-Wave devices
  services.udev.extraRules = ''
    # Zigbee devices
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="zigbee", GROUP="dialout", MODE="0660"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", SYMLINK+="zigbee", GROUP="dialout", MODE="0660"
    
    # Z-Wave devices
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0658", ATTRS{idProduct}=="0200", SYMLINK+="zwave", GROUP="dialout", MODE="0660"
  '';
}