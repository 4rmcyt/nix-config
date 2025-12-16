{config, ...}: {
  users.users.nut = {
    isSystemUser = true;
    group = "nut";
  };

  users.users.prometheus-nut-exporter = {
    extraGroups = ["nut"];
  };

  users.groups.nut = {};

  networking.firewall.allowedTCPPorts = [
    3493 # NUT (Network UPS Tools)
  ];

  power.ups = {
    enable = true;
    mode = "netserver";

    ups."apc" = {
      driver = "usbhid-ups";
      port = "auto";
      description = "APC Back-UPS ES 550";
    };

    upsd.listen = [
      {
        address = "0.0.0.0";
        port = 3493;
      }
    ];

    users.upsmon = {
      passwordFile = config.sops.secrets.nut_password.path;
      upsmon = "primary";
    };

    upsmon = {
      monitor.apc = {
        system = "apc@localhost";
        user = "upsmon";
        type = "primary";
      };
    };
  };

  sops.secrets.nut_password = {
    sopsFile = ../../../secrets/nut.yaml;
    owner = "root";
    group = "nut";
    mode = "0440";
  };
}
