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
      address = "0.0.0.0";
      port = 1883;
      users.iotdevice = {
        acl = [
          "read IoT/device/action"
          "write IoT/device/observations"
          "write IoT/device/LW"
        ];
        passwordFile = config.sops.secrets.mosquitto_iotdevice_password.path;
      };
      settings = {
        allow_anonymous = true;
        # Add more permissive settings for debugging
        max_connections = 100;
        max_keepalive = 65535;
        protocol = "mqtt";
      };
    }];

    # Add debug logging
    logDest = [ "stdout" ];
    logLevel = "debug";
  };
}
