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

  # upsd must start after upsdrv so the driver socket exists before upsd tries to connect
  # Use wants (not requires) to avoid stop ordering cycle that kills both services on rebuild
  systemd.services.upsd.after = ["upsdrv.service"];
  systemd.services.upsd.wants = ["upsdrv.service"];

  # Add prometheus-nut-exporter to nut group for password file access
  systemd.services.prometheus-nut-exporter = lib.mkIf config.services.prometheus.exporters.nut.enable {
    serviceConfig = {
      SupplementaryGroups = ["nut"];
    };
  };

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
