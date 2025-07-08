{ config, pkgs, ... }:

let
  # Define the Mosquitto password file content
  mosquittoPasswordContent = ''
    iotdevice:$(cat ${config.sops.secrets.mosquitto_iotdevice_password.path})
  '';

  # Define the Mosquitto ACL file content
  mosquittoAclContent = ''
    user iotdevice
    topic read IoT/device/action
    topic write IoT/device/observations
    topic write IoT/device/LW

    # If you want to allow anonymous users to connect but with no permissions,
    # you might add:
    # pattern write #
    # pattern read #
    # This would deny all access to anonymous users.
  '';

  # Create the actual Mosquitto configuration file
  # All Mosquitto settings are now defined within this single string
  mosquittoConfigFile = pkgs.writeText "mosquitto.conf" ''
    # Listener configuration
    listener 1883 0.0.0.0

    # Authentication and Authorization
    password_file ${pkgs.writeText "mosquitto-passwords" mosquittoPasswordContent}
    acl_file ${pkgs.writeText "mosquitto-acl" mosquittoAclContent}

    # General settings
    allow_anonymous true
    max_connections 100
    protocol mqtt # This refers to MQTT v3.1.1. For MQTT v5, use "mqttv5".

    # Logging settings
    log_type all
    log_dest stdout

    # Persistence (optional, but good practice for message retention)
    persistence true
    persistence_location /var/lib/mosquitto/
    # If you want to save the database periodically:
    # autosave_interval 1800 # Save every 30 minutes
  '';
in
{
  services.mosquitto = {
    enable = true;
    
    # Point Mosquitto to the custom configuration file.
    # This option should exist even in minimal modules.
    configFile = mosquittoConfigFile;

    # Ensure the mosquitto user has write access to the persistence location
    users.users.mosquitto.extraGroups = [ "mosquitto" ]; # Ensure mosquitto user exists and is in mosquitto group
    systemd.tmpfiles.rules = [
      "d /var/lib/mosquitto 0700 mosquitto mosquitto -"
    ];
  };

  # Define the sops secret for the Mosquitto IoT device password
  sops.secrets.mosquitto_iotdevice_password = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # Open port 1883 in the firewall
  networking.firewall.allowedTCPPorts = [ 1883 ];

  # Ensure the mosquitto user and group exist
  users.users.mosquitto = {
    isSystemUser = true;
    group = "mosquitto";
    home = "/var/lib/mosquitto"; # Set home to data directory for persistence
  };
  users.groups.mosquitto = {};
}
