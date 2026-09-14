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
      CapabilityBoundingSet = lib.mkForce "";
      NoNewPrivileges = lib.mkDefault true;
      PrivateDevices = lib.mkDefault true;
      # No AF_INET6 — homeserver-only module, networking.enableIPv6 = false
      # there. nixpkgs' upstream default here is AF_INET/AF_INET6/AF_UNIX;
      # with AF_INET6 present, `shh` (strace-profiling hardening helper)
      # crashes reading /proc/sys/net/ipv6/bindv6only, which doesn't exist
      # when IPv6 is fully disabled (confirmed live 2026-09-14, same crash
      # radarr/sonarr's comments already flagged this file as hitting).
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
      # TEMPORARY: forced (not mkDefault) to "default"/"all" for shh
      # profiling — ProcSubset=pid hides /proc/sys entirely from the
      # sandboxed process, and shh unconditionally reads
      # /proc/sys/net/ipv6/bindv6only while profiling regardless of this
      # unit's RestrictAddressFamilies, crashing with ENOENT. radarr/sonarr
      # don't hit this: their modules don't set ProtectProc/ProcSubset at
      # all (only nixpkgs' looser defaults). Revert to "invisible"/"pid"
      # once done profiling prowlarr.service, same cleanup pass as
      # kernel.yama.ptrace_scope in hosts/nixos/homeserver/hardening.nix.
      ProtectProc = lib.mkForce "default";
      ProcSubset = lib.mkForce "all";
      UMask = lib.mkDefault "0077";
      RemoveIPC = lib.mkDefault true;
      # Deliberately NOT setting SystemCallFilter/MemoryDenyWriteExecute:
      # *arr apps run on .NET, whose JIT needs W+X memory — same risk class
      # that killed alloy.service (Go) on gcp-relay. Not worth testing
      # against the whole *arr stack's indexer proxy.
    };
  };
}
