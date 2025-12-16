{
  config,
  lib,
  ...
}: {
  power.ups = {
    enable = true;
    mode = lib.mkDefault "netclient";

    users.upsmon = {
      passwordFile = config.sops.secrets.nut_password.path;
      upsmon = "slave";
    };

    upsmon = {
      monitor.apc = {
        system = "apc@homeserver";
        user = "upsmon";
        type = "slave";
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
