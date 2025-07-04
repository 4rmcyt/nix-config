services.mosquitto = {
  enable = true;
  listeners = [{
    address = "192.168.1.165";
    port = 1883;
    users.iotdevice = {
      acl = [
        "read IoT/device/action"
        "write IoT/device/observations"
        "write IoT/device/LW"
      ];
      password = "zeev:$2y$05$Fb1wQLtzujQ5m37aLH0qUeT.geHLbl0xC/EXL52WyHfLoJomSh9ue";
    };
  }];
  bridges."home-lab" = {
    addresses = [{
      address = "iot.labhome.work";
      port = 8883;
    }];
    topics = [
      "IoT/device/action in 1 \"\""
      "IoT/device/observations out 1 \"\""
      "IoT/device/LW out 0 \"\""
    ];
    settings = {
      local_clientid = "NiXOS-Mosquitto";
      remote_clientid = "NiXOS-Mosquitto";
      cleansession = true;
      notifications = false;
      start_type = "automatic";
      bridge_protocol_version = "mqttv311";
      bridge_outgoing_retain = false;
    };
  };
};

networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 1883 ];
};
