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
    # Removed: configFile = mosquittoConfigFile;
    # This option is reported as non-existent.
  };

  # Directly override the systemd service unit to use the custom config file.
  # This is a last resort when module options are too limited.
  systemd.services.mosquitto = {
    # Ensure the service starts after networking is up
    after = [ "network.target" ];
    # Set the ExecStart command to use your custom config file.
    # The actual path to mosquitto will be derived from pkgs.mosquitto.
    # This assumes the Mosquitto package provides a binary that accepts -c for config file.
    # Check `man mosquitto` or `mosquitto --help` for exact option if -c doesn't work.
    serviceConfig = {
      ExecStart = "${pkgs.mosquitto}/bin/mosquitto -c ${mosquittoConfigFile}";
      # Ensure the mosquitto user is set for the service
      User = "mosquitto";
      Group = "mosquitto";
      # Ensure the mosquitto user has write access to the persistence location
      # This is redundant if home is already set to /var/lib/mosquitto, but good for clarity.
      ReadWritePaths = [ "/var/lib/mosquitto" ];
    };
    # You might also need to explicitly bind mount the persistence location if PrivateMounts is true
    # systemd.services.mosquitto.serviceConfig.BindPaths = [ "/var/lib/mosquitto" ];
  };

  # Ensure the mosquitto user has write access to the persistence location
  systemd.tmpfiles.rules = [
    "d /var/lib/mosquitto 0700 mosquitto mosquitto -"
  ];

  # Define the sops secret for the Mosquitto IoT device password
  sops.secrets.mosquitto_iotdevice_password = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # Open port 1883 in the firewall
  # Ensure the mosquitto user and group exist
  users.users.mosquitto = {
    isSystemUser = true;
    group = "mosquitto";
    home = "/var/lib/mosquitto"; # Set home to data directory for persistence
  };
  users.groups.mosquitto = {};
}
