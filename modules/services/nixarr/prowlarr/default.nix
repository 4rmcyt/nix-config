{
  config,
  lib,
  ...
}: {
  imports = [
    # prowlarr_db_password is mode 0440 owner=postgres group=prowlarr.
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

  # Prowlarr reads PROWLARR__POSTGRES__* env vars natively (same mechanism as
  # every other Servarr app) -- no need to hand-edit config.xml via xmlstarlet.
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

      # nixpkgs' prowlarr module already sets DynamicUser=yes and
      # ProtectSystem=strict, but leaves CapabilityBoundingSet at the full
      # default set (verified via `systemctl show prowlarr.service`) — same
      # gap as bazarr/lidarr, unrelated to those two axes. Unlike bazarr,
      # prowlarr is a pure indexer proxy with no media-library filesystem
      # access outside its own dataDir (already granted, since it already
      # runs fine under ProtectSystem=strict), so the fuller set is safe
      # here.
      CapabilityBoundingSet = lib.mkDefault [];
      NoNewPrivileges = lib.mkDefault true;
      PrivateDevices = lib.mkDefault true;
      RestrictAddressFamilies = lib.mkDefault ["AF_INET" "AF_INET6" "AF_UNIX"];
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
      # Deliberately NOT setting SystemCallFilter/MemoryDenyWriteExecute:
      # *arr apps run on .NET, whose JIT needs W+X memory — same risk class
      # that killed alloy.service (Go) on gcp-relay. Not worth testing
      # against the whole *arr stack's indexer proxy.
    };
  };
}
