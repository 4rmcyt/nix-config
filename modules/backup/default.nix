{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.backup;
  pgDumpDir = "/var/backup/pg-dumps";
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

    systemd.tmpfiles.rules = lib.mkIf (cfg.postgresqlDatabases != []) [
      "d ${pgDumpDir} 0750 postgres postgres -"
    ];

    systemd.services.backup-pg-dump = lib.mkIf (cfg.postgresqlDatabases != []) {
      description = "Dump PostgreSQL databases for backup";
      after = ["postgresql.service"];
      requires = ["postgresql.service"];
      serviceConfig = {
        Type = "oneshot";
        User = "postgres";
      };
      script = ''
        DATE=$(date +%Y%m%d)
        ${lib.concatMapStringsSep "\n" (db: ''
          ${pkgs.postgresql}/bin/pg_dump -Fc ${db} > ${pgDumpDir}/${db}_$DATE.dump.tmp
          mv ${pgDumpDir}/${db}_$DATE.dump.tmp ${pgDumpDir}/${db}_$DATE.dump
          ls -t ${pgDumpDir}/${db}_*.dump 2>/dev/null | tail -n +8 | xargs rm -f
        '') cfg.postgresqlDatabases}
      '';
    };

    systemd.timers.backup-pg-dump = lib.mkIf (cfg.postgresqlDatabases != []) {
      description = "Timer for PostgreSQL dumps";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "02:30";
        Persistent = true;
      };
    };

    services.restic.backups.main = {
      initialize = true;
      inherit (cfg) repository;
      inherit (cfg) passwordFile;
      inherit (cfg) rcloneConfigFile;

      paths =
        cfg.paths
        ++ lib.optionals (cfg.postgresqlDatabases != []) [pgDumpDir];

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
    };
  };
}
