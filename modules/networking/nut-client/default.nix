{
  config,
  pkgs,
  ...
}: let
  # LAN address (kept off tailscale0 by modules/networking/lan-routing): on outage only the UPS-powered switch remains.
  upsSystem = "apc@${config.my.network.hosts.homeserver_lan}:${toString config.my.network.ports.nut}";

  # Secondary FSD skips setfsd and runs SHUTDOWNCMD locally; homeserver keeps running.
  upsschedCmd = pkgs.writeShellScript "upssched-cmd" ''
    case "$1" in
      onbatt) ${config.power.ups.package}/sbin/upsmon -c fsd ;;
    esac
  '';
in {
  users.groups.nut = {};

  systemd.tmpfiles.rules = [
    "d /run/upssched 0750 ${config.power.ups.upsmon.user} ${config.power.ups.upsmon.group} -"
  ];

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
      settings.NOTIFYFLAG = [
        ["ONBATT" "SYSLOG+WALL+EXEC"]
        ["ONLINE" "SYSLOG+WALL+EXEC"]
      ];
    };

    # Desktop draws most of the load; leave early so homeserver gets the battery.
    schedulerRules = toString (pkgs.writeText "upssched.conf" ''
      CMDSCRIPT ${upsschedCmd}
      PIPEFN /run/upssched/upssched.pipe
      LOCKFN /run/upssched/upssched.lock
      AT ONBATT * START-TIMER onbatt 30
      AT ONLINE * CANCEL-TIMER onbatt
    '');
  };

  # No wait-for-server unit: upsmon reconnects on its own if homeserver is down at boot.
  systemd.services.upsmon = {
    after = ["network-online.target"];
    wants = ["network-online.target"];
  };

  sops.secrets.nut_password = {
    sopsFile = ../../../secrets/nut.yaml;
    owner = "root";
    group = "nut";
    mode = "0440";
  };
}
