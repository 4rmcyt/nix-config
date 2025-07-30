{
  pkgs,
  config,
  lib,
  ...
}:
{

  services.postgresqlBackup = {
    enable = true;
    compression = "zstd";
    backupAll = true; # Backup all databases
    location = "/home/zeev/backup/postgres-backup/dump.sql";
    startAt = "*-*-* 01:15:00"; # Run daily at 01:15 AM
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
    settings = {
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

      storage = {
        compression = "zstd,1";
        borg_rsh = "ssh -o 'StrictHostKeyChecking=no' -i /home/zeev/.ssh/zeev";
        encryption_passcommand = "echo";
      };

      retention = {
        keep_daily = 7;
        keep_weekly = 4;
        keep_monthly = 6;
        prefix = "{hostname}-";
      };

      # Hooks are the key to integrating with other services.
      hooks = {
        # Commands to run BEFORE creating a backup.
        before_backup = [
          "echo 'Starting PostgreSQL dump via systemd...'"
          # This command tells systemd to run the postgresqlBackup service and wait for it to complete.
          # This guarantees a fresh dump file before borgmatic proceeds.
          "systemctl start --wait postgresql-backup.service"
          "echo 'PostgreSQL dump complete.'"
        ];
        # You can add failure hooks here to send notifications.
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
  # Configure the systemd timer for borgmatic.
  systemd.timers.borgmatic = {
      enable = true;
      wantedBy = ["timers.target"];
      timerConfig = {
        Unit = "borgmatic.service";
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "3h";
      };
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/postgres-backup 750 postgres postgres -"
  ];


}
