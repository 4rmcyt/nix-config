{
  config,
  lib,
  ...
}: {
  users.users.nut = {
    isSystemUser = true;
    group = "nut";
  };

  users.groups.nut = {};

  environment.etc."nut/upsd.conf".mode = "0640";

  systemd.tmpfiles.rules = [
    "z /etc/nut/upsd.conf 0640 root nut -"
  ];

  systemd.services.upsdrv.wantedBy = ["multi-user.target"];

  systemd.services.prometheus-nut-exporter = lib.mkIf config.services.prometheus.exporters.nut.enable {
    after = ["upsd.service"];
    wants = ["upsd.service"];
    serviceConfig = {
      SupplementaryGroups = ["nut"];
    };
  };

  networking.firewall.allowedTCPPorts = [
    config.my.network.ports.nut
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
        port = config.my.network.ports.nut;
      }
    ];

    users.upsmon = {
      passwordFile = config.sops.secrets.nut_password.path;
      upsmon = "primary";
    };

    users.homeassistant = {
      passwordFile = config.sops.secrets.nut_ha_password.path;
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

  sops.secrets.nut_ha_password = {
    sopsFile = ../../../secrets/nut.yaml;
    owner = "root";
    group = "nut";
    mode = "0440";
  };
}
