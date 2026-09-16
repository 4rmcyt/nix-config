{
  config,
  lib,
  ...
}: {
  imports = [
    ((import ../lib/pg-env.nix {inherit lib;}) {
      name = "prowlarr";
      envLines = [
        "PROWLARR__POSTGRES__HOST=127.0.0.1"
        "PROWLARR__POSTGRES__PORT=5432"
        "PROWLARR__POSTGRES__USER=prowlarr"
        "PROWLARR__POSTGRES__MAINDB=prowlarr"
        "PROWLARR__POSTGRES__LOGDB=prowlarr-log"
        "PROWLARR__POSTGRES__PASSWORD=%s"
      ];
      passwordSecretPath = config.sops.secrets.prowlarr_db_password.path;
    })
  ];

  # Reads PROWLARR__POSTGRES__* env vars natively — no need to hand-edit config.xml.
  services.prowlarr = {
    enable = true;
    dataDir = "/data/media/.state/nixarr/prowlarr";
    settings.server.port = config.my.network.ports.prowlarr;
  };

  systemd.services.prowlarr = {
    after = ["data.mount" "prowlarr-pg-env.service"];
    requires = ["data.mount" "prowlarr-pg-env.service"];
    serviceConfig = {
      EnvironmentFile = "/run/prowlarr-secrets/pg-env";

      # nixpkgs' module leaves CapabilityBoundingSet at the full default set (same gap
      # as bazarr/lidarr); safe to clear since prowlarr has no filesystem access outside dataDir.
      CapabilityBoundingSet = lib.mkForce "";
      NoNewPrivileges = lib.mkDefault true;
      PrivateDevices = lib.mkDefault true;
      # No AF_INET6: with IPv6 disabled on homeserver, `shh` crashes reading
      # /proc/sys/net/ipv6/bindv6only if AF_INET6 is present (same as radarr/sonarr).
      RestrictAddressFamilies = lib.mkForce ["AF_INET" "AF_UNIX"];
      ProtectClock = lib.mkDefault true;
      ProtectKernelLogs = lib.mkDefault true;
      ProtectKernelModules = lib.mkDefault true;
      ProtectKernelTunables = lib.mkDefault true;
      ProtectControlGroups = lib.mkDefault true;
      ProtectHostname = lib.mkDefault true;
      ProtectHome = lib.mkDefault true;
      RestrictNamespaces = lib.mkDefault true;
      RestrictSUIDSGID = lib.mkDefault true;
      LockPersonality = lib.mkDefault true;
      RestrictRealtime = lib.mkDefault true;
      ProtectProc = lib.mkDefault "invisible";
      ProcSubset = lib.mkDefault "pid";
      UMask = lib.mkDefault "0077";
      RemoveIPC = lib.mkDefault true;
      # Deliberately NOT setting MemoryDenyWriteExecute: *arr apps run .NET, whose JIT
      # needs W+X memory — same risk class that killed alloy.service (Go) on gcp-relay.
      PrivateMounts = true;
      SocketBindDeny = ["ipv4:udp" "ipv6:tcp" "ipv6:udp"];
      # A Nix list of "~@group:EPERM" strings renders as one SystemCallFilter= line
      # per element, but systemd only honors the leading "~" on the first line —
      # set SystemCallErrorNumber once and pass a single "~"-prefixed string instead.
      SystemCallErrorNumber = "EPERM";
      SystemCallFilter = "~@aio @chown @clock @cpu-emulation @debug @keyring @memlock @module @mount @obsolete @pkey @privileged @raw-io @reboot @sandbox @setuid @swap";
    };
  };
}
