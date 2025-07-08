# /etc/nixos/services/mosquitto-basic.nix
#
# A very basic Mosquitto configuration that enables the service
# and opens the default port 1883 for unauthenticated connections.

{ config, pkgs, ... }:

let
  # Create the basic Mosquitto configuration file content
  # All Mosquitto settings are now defined within this single string
  mosquittoConfigFile = pkgs.writeText "mosquitto.conf" ''
    # Listener configuration
    listener 1883 0.0.0.0

    # Allow anonymous connections (no username/password required).
    allow_anonymous true

    # Basic logging to stdout (journalctl)
    log_type all
    log_dest stdout

    # Persistence (optional, but good practice for message retention)
    persistence true
    persistence_location /var/lib/mosquitto/
  '';
in
{
  services.mosquitto = {
    enable = true;
    # Removed: listeners = [...];
    # Removed: extraConfig = '';
    # These options are not supported by your Nixpkgs version's Mosquitto module.
  };

  # Directly override the systemd service unit to use the custom config file.
  # This is necessary when module options are extremely limited.
  systemd.services.mosquitto = {
    # Ensure the service starts after networking is up
    after = [ "network.target" ];
    # Set the ExecStart command to use your custom config file.
    # We explicitly path the mosquitto binary and pass the -c option.
    serviceConfig = {
      ExecStart = "${pkgs.mosquitto}/bin/mosquitto -c ${mosquittoConfigFile}";
      # Ensure the service runs as the 'mosquitto' user and group
      User = "mosquitto";
      Group = "mosquitto";
      # Grant write access to the persistence location
      ReadWritePaths = [ "/var/lib/mosquitto" ];
      # Depending on your systemd sandbox settings, you might also need:
      # PrivateTmp = false;
      # PrivateDevices = false;
      # PrivateUsers = false;
      # ProtectSystem = "no";
      # ProtectHome = "no";
    };
  };

  # Open port 1883 in the system firewall.
  networking.firewall.allowedTCPPorts = [ 1883 ];

  # Define the mosquitto system user and group.
  users.users.mosquitto = {
    isSystemUser = true;
    group = "mosquitto";
    home = "/var/lib/mosquitto"; # Set home to data directory for persistence
  };
  users.groups.mosquitto = {};

  # Create the persistence directory for Mosquitto.
  systemd.tmpfiles.rules = [
    "d /var/lib/mosquitto 0700 mosquitto mosquitto -"
  ];
}
