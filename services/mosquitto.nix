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
      max_connections = 100;
      max_keepalive = 65535;
      protocol = "mqtt";
      log_type = [ "all" ]; # Enable all log types
      log_dest = [ "stdout" ]; # Log to stdout
    };
  }];
};