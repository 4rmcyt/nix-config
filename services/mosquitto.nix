{ config, pkgs, ... }:

{
  # SOPS secret for MQTT local user
  sops.secrets.mosquitto_iotdevice_password = {
    owner = "mosquitto";
    group = "mosquitto";
    mode = "0400";
  };

  services.mosquitto = {
    enable = true;
    listeners = [{
      address = "0.0.0.0";  # Allow connections from any IP
      port = 1883;
      users.iotdevice = {
        acl = [
          "read IoT/device/action"
          "write IoT/device/observations"
          "write IoT/device/LW"
        ];
        passwordFile = config.sops.secrets.mosquitto_iotdevice_password.path;
      };
      # Add anonymous access for testing (remove later)
      settings = {
        allow_anonymous = true;
      };
    }];
    # REMOVED: Bridge configuration - causing connection issues
  };
}