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

    # TEMPORARY 2026-09-14: entire shh-generated hardening block below
    # stripped for bisection — komga still fails with "Operation not
    # permitted" on Tomcat's own port bind (java.net.SocketException at
    # Net.bind0) after THREE different guessed causes (SocketBindDeny
    # ipv4:tcp, then AF_NETLINK, then SystemCallFilter syntax) each turned
    # out insufficient. Reverting to the known-working baseline (just
    # UMask/BindPaths/Environment, confirmed working this morning) to
    # re-add options in groups and actually isolate the real cause instead
    # of guessing further. Full block preserved in git history (this file,
    # commit before this one) — do not retype from scratch, restore pieces
    # from there once the real cause is found.
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/komga 0750 komga komga -"
    "d /var/lib/komga/tmp 0750 komga komga -"
  ];
}
