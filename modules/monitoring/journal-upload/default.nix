{
  config,
  lib,
  ...
}: let
  cfg = config.my.journalUpload;
in {
  options.my.journalUpload = {
    enable = lib.mkEnableOption "systemd-journal-upload of the local journal to VictoriaLogs";
    url = lib.mkOption {
      type = lib.types.str;
      default = "http://${config.my.network.hosts.homeserver_lan}:${toString config.my.network.ports.victorialogs-ingest}/insert/journald";
      description = "VictoriaLogs journald ingestion endpoint.";
    };
  };

  # No agent: systemd's own uploader; VictoriaLogs derives host/unit/level from journal fields.
  config = lib.mkIf cfg.enable {
    services.journald.upload = {
      enable = true;
      settings.Upload = {
        URL = cfg.url;
        Compression = "zstd";
      };
    };
  };
}
