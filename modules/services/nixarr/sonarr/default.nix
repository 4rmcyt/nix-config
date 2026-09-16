{
  config,
  lib,
  ...
}: {
  imports = [
    ((import ../lib/pg-env.nix {inherit lib;}) {
      name = "sonarr";
      envLines = [
        "SONARR__POSTGRES__HOST=127.0.0.1"
        "SONARR__POSTGRES__PORT=5432"
        "SONARR__POSTGRES__USER=sonarr"
        "SONARR__POSTGRES__MAINDB=sonarr"
        "SONARR__POSTGRES__LOGDB=sonarr-log"
        "SONARR__POSTGRES__PASSWORD=%s"
      ];
      passwordSecretPath = config.sops.secrets.sonarr_db_password.path;
    })
  ];

  # Reads SONARR__POSTGRES__* env vars natively — no need to hand-edit config.xml.
  services.sonarr = {
    enable = true;
    user = "sonarr";
    group = "sonarr";
    dataDir = "/data/media/.state/nixarr/sonarr";
    settings.server.port = config.my.network.ports.sonarr;
  };

  systemd.services.sonarr = {
    after = ["data.mount" "sonarr-pg-env.service"];
    requires = ["data.mount" "sonarr-pg-env.service"];
    serviceConfig = {
      EnvironmentFile = "/run/sonarr-secrets/pg-env";
      # nixpkgs' module hardcodes 0022; needs group-writable output to match the
      # rest of the media stack's shared "media" group access.
      UMask = lib.mkForce "0002";

      # No AF_INET6: with IPv6 disabled on homeserver, `shh` crashes reading
      # /proc/sys/net/ipv6/bindv6only if AF_INET6 is present (same as prowlarr).
      RestrictAddressFamilies = lib.mkForce ["AF_INET" "AF_UNIX"];

      ProtectSystem = "full";
      PrivateMounts = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      LockPersonality = true;
      RestrictRealtime = true;
      ProtectClock = true;
      SocketBindDeny = ["ipv4:udp" "ipv6:tcp" "ipv6:udp"];
      # Single-line value: splitting into separate Nix list entries would emit
      # multiple directive lines, and only the first would carry the leading "~".
      CapabilityBoundingSet = lib.mkForce "~CAP_BLOCK_SUSPEND CAP_BPF CAP_CHOWN CAP_IPC_LOCK CAP_KILL CAP_MKNOD CAP_NET_RAW CAP_PERFMON CAP_SYS_BOOT CAP_SYS_CHROOT CAP_SYS_MODULE CAP_SYS_PACCT CAP_SYS_PTRACE CAP_SYS_TIME CAP_SYS_TTY_CONFIG CAP_SYSLOG CAP_WAKE_ALARM";
      # A Nix list of "~@group:EPERM" strings renders as one SystemCallFilter= line
      # per element, but systemd only honors the leading "~" on the first — use a
      # single "~"-prefixed string with SystemCallErrorNumber set separately instead.
      SystemCallErrorNumber = "EPERM";
      SystemCallFilter = "~@aio @chown @clock @cpu-emulation @debug @keyring @memlock @module @mount @obsolete @pkey @privileged @raw-io @reboot @sandbox @setuid @swap";
    };
  };
}
