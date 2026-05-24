{
  config,
  pkgs,
  ...
}: {
  users.groups.nut = {};

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

  systemd.services.nut-wait-homeserver = {
    description = "Wait for NUT server on homeserver:3493";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    before = ["upsmon.service"];
    wantedBy = ["upsmon.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'until ${pkgs.netcat-gnu}/bin/nc -z homeserver 3493; do sleep 2; done'";
    };
  };

  systemd.services.upsmon = {
    after = ["network-online.target" "nut-wait-homeserver.service"];
    wants = ["network-online.target"];
    requires = ["nut-wait-homeserver.service"];
  };

  sops.secrets.nut_password = {
    sopsFile = ../../../secrets/nut.yaml;
    owner = "root";
    group = "nut";
    mode = "0440";
  };
}
