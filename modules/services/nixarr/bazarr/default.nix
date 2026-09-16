{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ((import ../lib/pg-env.nix {inherit lib;}) {
      name = "bazarr";
      envLines = [
        "POSTGRES_ENABLED=true"
        "POSTGRES_HOST=127.0.0.1"
        "POSTGRES_PORT=5432"
        "POSTGRES_DATABASE=bazarr"
        "POSTGRES_USERNAME=bazarr"
        "POSTGRES_PASSWORD=%s"
      ];
      passwordSecretPath = config.sops.secrets.bazarr_db_password.path;
    })
  ];

  # Custom post-processing burns subtitles in via libass for clients that can't render
  # some glyphs as text (e.g. Hebrew on Roku); ffmpeg isn't otherwise on bazarr's PATH.
  systemd.services.bazarr.path = [pkgs.ffmpeg];

  # Reads these same POSTGRES_* env vars natively and gives them precedence over config.yaml.
  services.bazarr = {
    enable = true;
    user = "bazarr";
    group = "bazarr";
    dataDir = "/data/media/.state/nixarr/bazarr";
    listenPort = config.my.network.ports.bazarr;
  };

  systemd.services.bazarr = {
    after = ["data.mount" "bazarr-pg-env.service"];
    requires = ["data.mount" "bazarr-pg-env.service"];
    serviceConfig = {
      EnvironmentFile = "/run/bazarr-secrets/pg-env";

      # Unlike radarr/sonarr/prowlarr (.NET, need W+X JIT memory), bazarr is Python —
      # no W+X memory use observed, so MemoryDenyWriteExecute is safe here.
      ProtectSystem = "full";
      ProtectHome = true;
      PrivateTmp = "disconnected";
      PrivateDevices = true;
      PrivateMounts = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      LockPersonality = true;
      RestrictRealtime = true;
      ProtectClock = true;
      MemoryDenyWriteExecute = true;
      RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_NETLINK" "AF_UNIX"];
      SocketBindDeny = ["ipv4:udp" "ipv6:udp"];
      # A Nix list of "~@group:EPERM" strings renders as one SystemCallFilter= line
      # per element, but systemd only honors the leading "~" on the first — use a
      # single "~"-prefixed string with SystemCallErrorNumber set separately instead.
      SystemCallErrorNumber = "EPERM";
      SystemCallFilter = "~@aio @chown @clock @cpu-emulation @debug @keyring @memlock @module @mount @obsolete @pkey @privileged @raw-io @reboot @sandbox @setuid @swap";
    };
  };
}
