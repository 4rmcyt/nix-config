{ config, pkgs, ... }:

{
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
        log_type = [ "all" ];
        log_dest = [ "stdout" ];
      };
    }];
  };

  # SOPS secret for Mosquitto
  sops.secrets.mosquitto_iotdevice_password = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # Open firewall port for Mosquitto
  networking.firewall.allowedTCPPorts = [ 1883 ];
}