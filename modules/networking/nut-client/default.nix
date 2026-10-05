{
  config,
  pkgs,
  ...
}: let
  # LAN address: on outage the router is down, only the UPS-powered switch remains.
  upsSystem = "apc@${config.my.network.hosts.homeserver_lan}:${toString config.my.network.ports.nut}";

  # Beats Tailscale's `5270 lookup 52` (accepted homeserver subnet route) for NUT only.
  nutRule = "to ${config.my.network.hosts.homeserver_lan} ipproto tcp dport ${toString config.my.network.ports.nut} lookup main priority 5200";

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

  systemd.services.nut-lan-route = {
    description = "Route NUT traffic to homeserver via LAN, bypassing Tailscale";
    before = ["upsmon.service"];
    wantedBy = ["upsmon.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "-${pkgs.iproute2}/bin/ip rule del ${nutRule}";
      ExecStart = "${pkgs.iproute2}/bin/ip rule add ${nutRule}";
      ExecStop = "${pkgs.iproute2}/bin/ip rule del ${nutRule}";
    };
  };

  # No wait-for-server unit: upsmon reconnects on its own if homeserver is down at boot.
  systemd.services.upsmon = {
    after = ["network-online.target" "nut-lan-route.service"];
    wants = ["network-online.target"];
  };

  sops.secrets.nut_password = {
    sopsFile = ../../../secrets/nut.yaml;
    owner = "root";
    group = "nut";
    mode = "0440";
  };
}
