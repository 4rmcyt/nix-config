{config, ...}: {
  power.ups = {
    enable = true;
    mode = "netclient";

    users.upsmon = {
      passwordFile = config.sops.secrets.nut_password.path;
      upsmon = "secondary";
    };

    upsmon = {
      monitor.apc = {
        system = "apc@homeserver";
        user = "upsmon";
        type = "secondary";
      };
    };
  };

  sops.secrets.nut_password = {
    sopsFile = ../../../secrets/nut.yaml;
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
