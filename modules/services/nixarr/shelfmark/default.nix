{
  config,
  lib,
  ...
}: let
  inherit (config.my.network.ports) shelfmark;
  cfg = config.nixarr.shelfmark;
  tmpDir = "/data/Downloads/shelfmark";
in {
  nixarr.shelfmark = {
    enable = true;
    port = shelfmark;
  };

  # Defaults only; the web UI can override them.
  services.shelfmark.environment = {
    INGEST_DIR = "/data/media/books";
    DESTINATION_AUDIOBOOK = "/data/media/audiobooks";
    TMP_DIR = tmpDir;
  };

  systemd.services.shelfmark = {
    after = ["data.mount"];
    requires = ["data.mount"];
    # On top of the nixpkgs module's sandbox (ProtectSystem=strict, PrivateUsers, empty caps, @system-service).
    serviceConfig = {
      # nixarr grants all of mediaDir; narrow to the two library roots + staging.
      ReadWritePaths = lib.mkForce [
        cfg.stateDir
        "/data/media/books"
        "/data/media/audiobooks"
        tmpDir
      ];
      # Package sets USING_EXTERNAL_BYPASSER (no bundled Chromium), so no JIT needs W+X.
      MemoryDenyWriteExecute = true;
      SocketBindAllow = ["tcp:${toString shelfmark}"];
      SocketBindDeny = "any";
      SystemCallErrorNumber = "EPERM";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${tmpDir} 775 shelfmark media -"
  ];
}
