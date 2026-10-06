{
  config,
  lib,
  pkgs,
  ...
}: let
  # Forces FSD on upsd: secondaries (desktop) shut down first, then this host, then killpower.
  upsschedCmd = pkgs.writeShellScript "upssched-cmd" ''
    case "$1" in
      onbatt) ${config.power.ups.package}/sbin/upsmon -c fsd ;;
    esac
  '';
in {
  users.users.nut = {
    isSystemUser = true;
    group = "nut";
  };

  users.groups.nut = {};

  environment.etc."nut/upsd.conf".mode = "0640";

  systemd.tmpfiles.rules = [
    "z /etc/nut/upsd.conf 0640 root nut -"
    "d /run/upssched 0750 ${config.power.ups.upsmon.user} ${config.power.ups.upsmon.group} -"
  ];

  systemd.services.upsdrv = {
    wantedBy = ["multi-user.target"];
    # usbhid-ups can hang after SIGTERM; default 90s stall eats battery during FSD.
    serviceConfig.TimeoutStopSec = "10s";
  };

  # nixpkgs still runs `upsd -u root` (upstream TODO); keep uid 0 but strip what it can do.
  systemd.services.upsd.serviceConfig = {
    # SETUID/SETGID for become_user()'s initgroups/setgid/setuid, CHOWN for ExecStartPre's `install -o root`.
    CapabilityBoundingSet = ["CAP_SETUID" "CAP_SETGID" "CAP_CHOWN"];
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    # NUT_STATEPATH (driver sockets, pidfile) and the rendered upsd.users.
    ReadWritePaths = ["/var/lib/nut" "/run/nut"];
    PrivateTmp = true;
    ProtectHome = true;
    # USB belongs to upsdrv (separate unit); upsd only talks to the driver socket.
    PrivateDevices = true;
    ProtectClock = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectControlGroups = true;
    ProtectHostname = true;
    ProtectProc = "invisible";
    ProcSubset = "pid";
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = ["@system-service"];
    SystemCallErrorNumber = "EPERM";
    RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
  };

  # Root parent runs SHUTDOWNCMD, child drops to nutmon via `-u`.
  systemd.services.upsmon.serviceConfig = {
    # SETUID/SETGID for the drop; CHOWN/FOWNER/DAC_OVERRIDE for ExecStartPre's `install -o nutmon` + replace-secret on a nutmon-owned 0600 file.
    CapabilityBoundingSet = ["CAP_SETUID" "CAP_SETGID" "CAP_CHOWN" "CAP_FOWNER" "CAP_DAC_OVERRIDE"];
    NoNewPrivileges = true;
    # full, not strict: POWERDOWNFLAG (/run/killpower) is created at FSD time, can't pre-list it.
    ProtectSystem = "full";
    PrivateTmp = true;
    ProtectHome = true;
    PrivateDevices = true;
    ProtectClock = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectControlGroups = true;
    ProtectHostname = true;
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = ["@system-service"];
    SystemCallErrorNumber = "EPERM";
    RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
  };

  systemd.services.prometheus-nut-exporter = lib.mkIf config.services.prometheus.exporters.nut.enable {
    after = ["upsd.service"];
    wants = ["upsd.service"];
    serviceConfig = {
      SupplementaryGroups = ["nut"];
    };
  };

  # Only desktop's upsmon is remote; HA (host network) and the exporter use loopback.
  networking.firewall.extraInputRules = ''
    iifname "enp0s31f6" ip saddr { ${config.my.network.hosts.desktop_lan}, ${config.my.network.hosts.desktop_wifi} } tcp dport ${toString config.my.network.ports.nut} accept
  '';

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

    # Secondary can't request FSD, so a leaked desktop password can't power off homeserver.
    users.upsmon-desktop = {
      passwordFile = config.sops.secrets.nut_desktop_password.path;
      upsmon = "secondary";
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
      settings.NOTIFYFLAG = [
        ["ONBATT" "SYSLOG+WALL+EXEC"]
        ["ONLINE" "SYSLOG+WALL+EXEC"]
      ];
    };

    # Desktop leaves after 30s (nut-client); homeserver alone lasts ~9 min to LB, so FSD at 5 min.
    schedulerRules = toString (pkgs.writeText "upssched.conf" ''
      CMDSCRIPT ${upsschedCmd}
      PIPEFN /run/upssched/upssched.pipe
      LOCKFN /run/upssched/upssched.lock
      AT ONBATT * START-TIMER onbatt 300
      AT ONLINE * CANCEL-TIMER onbatt
    '');
  };

  sops.secrets.nut_password = {
    sopsFile = ../../../secrets/nut.yaml;
    owner = "root";
    group = "nut";
    mode = "0440";
  };

  sops.secrets.nut_desktop_password = {
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
