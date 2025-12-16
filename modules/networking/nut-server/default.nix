{config, ...}: {
  users.users.nut = {
    isSystemUser = true;
    group = "nut";
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

    users.upsmon = {
      passwordFile = config.sops.secrets.nut_password.path;
      upsmon = "master";
    };

    upsmon = {
      monitor.apc = {
        system = "apc@localhost";
        user = "upsmon";
        type = "master";
      };
    };
  };

  sops.secrets.nut_password = {
    sopsFile = ../../../secrets/nut.yaml;
    owner = "nut";
    group = "nut";
    mode = "0400";
  };
}
