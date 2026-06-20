{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.backup;
in {
  options.my.backup = {
    enable = lib.mkEnableOption "restic backups to Google Drive via rclone";

    passwordFile = lib.mkOption {
      type = lib.types.str;
      description = "Path to restic repository password file (sops secret path).";
    };

    rcloneConfigFile = lib.mkOption {
      type = lib.types.str;
      description = "Path to rclone config file with Google Drive remote (sops secret path).";
    };

    repository = lib.mkOption {
      type = lib.types.str;
      description = "Restic repository path (e.g. rclone:gdrive:restic/homeserver).";
    };

    postgresqlDatabases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "PostgreSQL databases to dump and include in backup.";
    };

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra filesystem paths to include in backup.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.postgresqlDatabases == [] || config.services.postgresql.enable;
        message = "my.backup: postgresqlDatabases requires services.postgresql.enable = true";
      }
    ];

    environment.systemPackages = [pkgs.restic];

    systemd.services.backup-pg-dump = lib.mkIf (cfg.postgresqlDatabases != []) {
      description = "Dump PostgreSQL databases for restic backup";
      before = ["restic-backups-main.service"];
      requiredBy = ["restic-backups-main.service"];
      after = ["postgresql.service"];
      requires = ["postgresql.service"];
      serviceConfig = {
        Type = "oneshot";
        User = "postgres";
        RuntimeDirectory = "backup-pg-dumps";
        RuntimeDirectoryMode = "0700";
      };
      script = lib.concatMapStringsSep "\n" (db: ''
        ${pkgs.postgresql}/bin/pg_dump -Fc ${db} > /run/backup-pg-dumps/${db}.dump
      '') cfg.postgresqlDatabases;
    };

    services.restic.backups.main = {
      initialize = true;
      repository = cfg.repository;
      passwordFile = cfg.passwordFile;
      rcloneConfigFile = cfg.rcloneConfigFile;

      paths =
        cfg.paths
        ++ lib.optionals (cfg.postgresqlDatabases != []) ["/run/backup-pg-dumps"];

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];

      timerConfig = {
        OnCalendar = "03:00";
        RandomizedDelaySec = "30min";
        Persistent = true;
      };

      backupCleanupCommand = lib.mkIf (cfg.postgresqlDatabases != []) ''
        rm -rf /run/backup-pg-dumps
      '';
    };
  };
}
