{
  config,
  pkgs,
  lib,
  ...
}:
{
  users.groups.nut = { };

  power.ups = {
    enable = true;
    mode = "netclient";

    upsmon = {
      monitor.apc = {
        system = "apc@homeserver";
        user = "upsmon";
        type = "secondary";
        passwordFile = config.sops.secrets.nut_password.path;
      };
    };
  };

  systemd.services.upsmon = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig.ExecStartPre = lib.mkDefault "${pkgs.coreutils}/bin/sleep 10";
  };

  sops.secrets.nut_password = {
    sopsFile = ../../../secrets/nut.yaml;
    owner = "root";
    group = "nut";
    mode = "0440";
  };
}
