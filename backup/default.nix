{ pkgs, config, lib, ... }:

{
  # 1. Configure PostgreSQL Backup to run ON-DEMAND via the hook.
  services.postgresqlBackup = {
    enable = true;
    compression = "zstd";
    backupAll = true;
    location = "/var/lib/postgres-backup/dump.sql";
  };

  services.borgmatic = {
    enable = true;
    location = {
      source_directories = [
         "/home/zeev"
         "/var/log"
         "/var/lib/postgres-backup" # Include the directory where the dump will be.
         "/var/lib/home-assistant"
         "/var/lib/kavita"
         "/var/lib/miniflux"
         "/var/lib/mosquitto"
         "/var/lib/paperless"
         "/var/lib/prometheus2"
         "/var/lib/radicale"
         "/var/lib/sops"
         "/var/lib/calibre-web"
         "/var/lib/grafana"
         "/var/lib/microbin"
         "/var/lib/homepage-dashboard"
         "/var/lib/nixos"
         "/data/.secret"
         "/data/media/.state"
         "/data/media/"
      ];
      repositories = [ "ssh://uu478963@u478963.your-storagebox.de:23//media/backup/main-backup" ];
      exclude_patterns = [
          # Home directory excludes
          "/home/zeev/Downloads"
          "/home/zeev/backups"
          "/home/zeev/.cache"
          "/home/zeev/.config/Slack/logs"
          "/home/zeev/.config/Code/CachedData"
          "/home/zeev/.npm/_cacache"
          "*/node_modules"
          "*/venv"
          "*/.venv"

          # General system excludes
          "/var/lib/systemd"
          "/var/lib/containers"
          "/var/lib/flatpak"
          "/var/lib/docker"
          "/var/lib/Podman"

          # Wildcard excludes
          "*/.Trash"
          "*/Cache"
          "*/cache2"
          "/home/*/.local/share/Trash"
          "/home/*/.local/share/containers"
      ];
    };
    settings = {
      storage = {
        compression = "zstd,1";
        borg_rsh = "ssh -o 'StrictHostKeyChecking=no' -i /zeev/home/.ssh/zeev";
        encryption_passcommand = config.sops.secrets.borgmatic_encryption_pass.path;
      };

      retention = {
        keep_daily = 7;
        keep_weekly = 4;
        keep_monthly = 6;
        prefix = "{hostname}-";
      };

      hooks = {
        # This hook runs the postgres dump right before the backup starts.
        before_backup = [
          "echo 'Starting PostgreSQL dump via systemd...'"
          "systemctl start --wait postgresql-backup.service"
          "echo 'PostgreSQL dump complete.'"
        ];
        on_failure = [{
          command = ''
            export DISPLAY=:0
            export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u zeev)/bus"
            sudo -u zeev ${pkgs.libnotify}/bin/notify-send -u critical "Borgmatic Backup FAILED!" "Run 'journalctl -u borgmatic.service' for details"
          '';
        }];
      };
    };
  };

  # Configure the systemd timer for borgmatic itself. This is correct.
  systemd.timers.borgmatic = {
    enable = true;
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Unit = "borgmatic.service";
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "3h";
    };
  };

  # This rule correctly creates the directory for the postgresqlBackup service.
  systemd.tmpfiles.rules = [
    "d /var/lib/postgres-backup 750 postgres postgres -"
  ];
}