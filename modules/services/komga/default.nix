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

    # /tmp is noexec on homeserver, which breaks sqlite-jdbc's native .so mmap
    # (mis-reported as NativeLibraryNotFoundException) — /var/lib is exec there, so
    # point java.io.tmpdir at /var/lib/komga/tmp instead.
    # nixpkgs' komga wrapper only puts libwebp on LD_LIBRARY_PATH; libheif/libjxl exist
    # in nixpkgs but aren't wired in, so those format plugins silently disable otherwise.
    Environment = [
      "JAVA_TOOL_OPTIONS=-Djava.io.tmpdir=/var/lib/komga/tmp"
      "LD_LIBRARY_PATH=${lib.makeLibraryPath [pkgs.libheif pkgs.libjxl]}"
    ];

    # nixpkgs' komga.nix hardcodes PrivateTmp, RestrictAddressFamilies, and
    # CapabilityBoundingSet as plain (not mkDefault) — needs mkForce.
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
    # AF_NETLINK required: Tomcat's NIO endpoint needs netlink for interface enumeration
    # before bind, unrelated to IPv6. This file is the single source of truth for
    # komga's hardening — do not re-add a duplicate serviceConfig elsewhere.
    RestrictAddressFamilies = lib.mkForce ["AF_INET" "AF_INET6" "AF_NETLINK"];
    SocketBindDeny = ["ipv4:udp" "ipv6:udp"];
    # A Nix list of "~@group:EPERM" strings renders as multiple SystemCallFilter= lines,
    # but systemd only honors the leading "~" on the first — use a single string instead.
    SystemCallErrorNumber = "EPERM";
    SystemCallFilter = "~@aio @chown @clock @cpu-emulation @debug @keyring @memlock @module @mount @obsolete @pkey @privileged @raw-io @reboot @resources @sandbox @setuid @swap";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/komga 0750 komga komga -"
    "d /var/lib/komga/tmp 0750 komga komga -"
  ];
}
