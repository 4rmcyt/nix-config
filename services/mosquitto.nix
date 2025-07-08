# /etc/nixos/services/mosquitto-basic.nix
#
# A very basic Mosquitto configuration that enables the service
# and opens the default port 1883 for unauthenticated connections.

{ config, pkgs, ... }:

{
  services.mosquitto = {
    enable = true;
    
    # Configure a listener for the standard MQTT port on all interfaces.
    listeners = [{
      address = "0.0.0.0";
      port = 1883;
    }];

    # Allow anonymous connections (no username/password required).
    # This is suitable for a basic setup but consider authentication for production.
    extraConfig = ''
      allow_anonymous true
    '';

    # Basic logging to stdout (journalctl)
    logType = [ "all" ];
    logDest = [ "stdout" ];
  };

  # Open port 1883 in the system firewall.
  networking.firewall.allowedTCPPorts = [ 1883 ];

  # Define the mosquitto system user and group if they don't exist globally.
  # This is good practice to ensure the service runs with proper permissions.
  users.users.mosquitto = {
    isSystemUser = true;
    group = "mosquitto";
    home = "/var/lib/mosquitto"; # Default home for persistence
  };
  users.groups.mosquitto = {};

  # Create the persistence directory for Mosquitto.
  systemd.tmpfiles.rules = [
    "d /var/lib/mosquitto 0700 mosquitto mosquitto -"
  ];
}
