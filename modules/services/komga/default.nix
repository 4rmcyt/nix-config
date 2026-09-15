{
  config,
  pkgs,
  lib,
  ...
}: {
  users.users.komga = {
    isSystemUser = true;
    group = "komga";
    extraGroups = [
      "users"
      "media"
    ];
  };
  users.groups.komga = {};

  services.komga = {
    enable = true;
    settings = {
      "spring.datasource.url" = "jdbc:h2:file:/var/lib/komga/database;DB_CLOSE_ON_EXIT=FALSE";
      server.port = config.my.network.ports.komga;
    };
  };

  systemd.services.komga.serviceConfig = {
    UMask = "0002";
    BindPaths = [
      "/data/media/comics"
      "/data/media/manga"
      "/data/media/books"
    ];

    # komga is homeserver-only, and /tmp + /var/tmp are noexec there
    # (nix-mineral filesystem hardening default, see
    # hosts/nixos/homeserver/hardening.nix). sqlite-jdbc (bundled inside
    # komga for its search index) extracts its native .so to java.io.tmpdir
    # and mmaps it PROT_EXEC — under noexec that fails, and sqlite-jdbc
    # mis-reports the failure as "NativeLibraryNotFoundException" instead of
    # a permission error. /var/lib is already carved out exec on homeserver
    # (filesystems.normal."/var/lib" in hardening.nix, for the *arr stack's
    # own scripts) — point java.io.tmpdir at /var/lib/komga/tmp instead of
    # PrivateTmp's /tmp.
    # nixpkgs' komga wrapper only puts libwebp on LD_LIBRARY_PATH (verified
    # via `cat` on the wrapper script) — libheif and libjxl are both
    # available in nixpkgs but the package doesn't wire them in, so their
    # image-format plugins log "Could not load libheif"/"Could not load
    # libjxl" and silently disable at startup (confirmed live 2026-09-14).
    # The wrapper prepends its own LD_LIBRARY_PATH entry onto whatever it
    # inherits, so this is additive, not a fight over who wins.
    Environment = [
      "JAVA_TOOL_OPTIONS=-Djava.io.tmpdir=/var/lib/komga/tmp"
      "LD_LIBRARY_PATH=${lib.makeLibraryPath [pkgs.libheif pkgs.libjxl]}"
    ];

    # BISECT 2026-09-14, round 1: baseline (just UMask/BindPaths/Environment)
    # confirmed working live. Re-adding the non-networking half of the
    # shh-generated hardening now (mount/kernel-protection directives +
    # CapabilityBoundingSet); RestrictAddressFamilies/SocketBindDeny/
    # SystemCallFilter deliberately left out this round to isolate whether
    # the bind failure lives in this half or the networking/syscall half.
    ProtectSystem = "full";
    ProtectHome = true;
    PrivateTmp = lib.mkForce "disconnected";
    PrivateDevices = true;
    PrivateMounts = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectKernelLogs = true;
    ProtectControlGroups = true;
    LockPersonality = true;
    RestrictRealtime = true;
    ProtectClock = true;
    CapabilityBoundingSet = lib.mkForce "~CAP_BLOCK_SUSPEND CAP_BPF CAP_CHOWN CAP_IPC_LOCK CAP_MKNOD CAP_NET_RAW CAP_PERFMON CAP_SYS_BOOT CAP_SYS_CHROOT CAP_SYS_MODULE CAP_SYS_NICE CAP_SYS_PACCT CAP_SYS_PTRACE CAP_SYS_TIME CAP_SYSLOG CAP_WAKE_ALARM";

    # BISECT round 2: round 1 (above) confirmed working live 2026-09-14
    # (komga served 200 OK with just mount/kernel-protection + capabilities).
    # Adding the networking restrictions now, from a fresh shh profile —
    # SystemCallFilter deliberately still left out, to isolate it from
    # RestrictAddressFamilies/SocketBindDeny as a separate round.
    RestrictAddressFamilies = lib.mkForce ["AF_INET" "AF_INET6"];
    SocketBindDeny = ["ipv4:udp" "ipv6:udp"];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/komga 0750 komga komga -"
    "d /var/lib/komga/tmp 0750 komga komga -"
  ];
}
