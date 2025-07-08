{ config, pkgs, ... }:

let
  # Define the Mosquitto password file content
  mosquittoPasswordFile = pkgs.writeText "mosquitto-passwords" ''
    iotdevice:$(cat ${config.sops.secrets.mosquitto_iotdevice_password.path})
  '';

  # Define the Mosquitto ACL file content
  mosquittoAclFile = pkgs.writeText "mosquitto-acl" ''
    user iotdevice
    topic read IoT/device/action
    topic write IoT/device/observations
    topic write IoT/device/LW

    # If you want to allow anonymous users to connect but with no permissions,
    # you might add:
    # pattern write #
    # pattern read #
    # This would deny all access to anonymous users.
    # If you remove allow_anonymous true, then all users must authenticate.
  '';
in
{
  services.mosquitto = {
    enable = true;
    
    # Define listeners at the top level of services.mosquitto
    listeners = [{
      address = "0.0.0.0";
      port = 1883;
      # Settings specific to this listener can go here if needed,
      # but allow_anonymous, max_connections, protocol are usually global.
      # You can override them per listener if you have multiple.
    }];

    # Set password file and ACL file globally for the broker
    passwordFile = mosquittoPasswordFile;
    aclFile = mosquittoAclFile;

    # Global Mosquitto settings
    extraConfig = ''
      # It's recommended to set allow_anonymous to false if you want to enforce authentication.
      # If allow_anonymous is true, any client can connect without credentials.
      allow_anonymous true
      max_connections 100
      protocol mqtt # This refers to MQTT v3.1.1. For MQTT v5, use "mqttv5".
    '';

    logType = [ "all" ];
    logDest = [ "stdout" ];
  };

  sops.secrets.mosquitto_iotdevice_password = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  networking.firewall.allowedTCPPorts = [ 1883 ];
}