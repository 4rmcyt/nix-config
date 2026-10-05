{
  config,
  pkgs,
  ...
}: let
  # LAN, not MagicDNS: on outage the router is down, only the UPS-powered switch remains.
  upsSystem = "apc@${config.my.network.hosts.homeserver_lan}:${toString config.my.network.ports.nut}";
in {
  users.groups.nut = {};

  power.ups = {
    enable = true;
    mode = "netclient";

    upsmon = {
      monitor.apc = {
        system = upsSystem;
        user = "upsmon";
        type = "secondary";
        passwordFile = config.sops.secrets.nut_password.path;
      };
    };
  };

  systemd.services.nut-wait-homeserver = {
    description = "Wait for NUT server on homeserver:${toString config.my.network.ports.nut}";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    before = ["upsmon.service"];
    wantedBy = ["upsmon.service"];
    serviceConfig = {
      Type = "oneshot";
      # Bounded retry: fail fast instead of hanging boot forever if
      # homeserver's NUT server is unreachable; systemd's Restart=on-failure
      # then retries the whole unit.
      ExecStart = "${pkgs.bash}/bin/bash -c 'for i in $(seq 1 30); do ${pkgs.nut}/bin/upsc ${upsSystem} &>/dev/null && exit 0; sleep 2; done; exit 1'";
      Restart = "on-failure";
      RestartSec = "10s";
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
