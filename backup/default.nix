# Borgmatic
#
# This handles backing up my server's docker files to my laptop and to my backup server
#

{ config,
  pkgs,
  lib, ... }:
{
  services.postgresqlBackup = {
    enable = true;
    compression = "zstd";
    backupAll = true;
    location = "/var/lib/postgres-backup/dump.sql";
  };
  services.borgmatic = {
    enable = true;
    settings = {
      # Sources
      source_directories = [
        "/home/zeev"
        "/var/log"
        "/var/lib/postgres-backup"
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
        "/etc"
      ];
      # Excludes
      exclude_patterns = [
          "/home/zeev/Downloads"
          "/home/zeev/backups"
          "/home/zeev/.cache"
          "/home/zeev/.npm/_cacache"
          "*/node_modules"
          "*/venv"
          "*/.venv"
          "/var/lib/systemd"
          "/var/lib/containers"
          "/var/lib/flatpak"
          "/var/lib/docker"
          "/var/lib/Podman"
          "*/.Trash"
          "*/Cache"
          "*/cache2"
          "/home/*/.local/share/Trash"
          "/home/*/.local/share/containers"
        ];
      exclude_if_present = [
        ".nobackup"
        ".stversions"
        ".thumbnails"
      ];

      # Repositories
      repositories = [
        {
          label = "On Disk Backup";
          path = "/data/backup/borg";
        }
        {
          label = "Backup Server";
          path = "ssh://u478963@u478963.your-storagebox.de:23/./borg/hostname/${config.networking.hostName}";
        }
      ];
      encryption_passcommand = "${pkgs.coreutils}/bin/cat $${config.sops.secrets.borgmatic_encryption_pass.path}";
      ssh_command = "ssh -i " + config.sops.secrets.borg_private_key.path;

      # Backup Settings
      compression = "lz4";
      archive_name_format = "backup-{now}";
      relocated_repo_access_is_ok = true;

      # Retention
      keep_hourly = 24;
      keep_daily = 7;
      keep_weekly = 4;
      keep_monthly = 12;
      keep_yearly = 3;

      # Hooks
      before_backup = [
        "echo Starting a backup job."
        "${pkgs.iputils}/bin/ping -q -c 1 192.168.1.165 > /dev/null || exit 75"
      ];
      after_backup = [
        "echo Backup created."
      ];
      on_error = [
        "echo Error while creating a backup."
      ];

      # Consistency Checks
      checks = [
        {
          name = "repository";
          frequency = "always";
        }
        {
          name = "archives";
          frequency = "always";
        }
        {
          name = "data";
          frequency = "always";
        }
        {
          name = "extract";
          frequency = "always";
        }
      ];
      check_last = 3;

      # Notifications
      # uptime_kuma = {
      #   push_url = "http://uptime-kuma.heimdall.technet/api/push/nDXOzelHhZ";
      #   states = [
      #     #"start"
      #     "finish"
      #     "fail"
      #   ];
      # };
    };
  };
  users.users.borgmatic = {
    isSystemUser = true;
    group = "borgmatic";
    extraGroups = [
      "users"
      "media"
    ];
  };
  users.groups.borgmatic = { };

  systemd.tmpfiles.rules = [
    "D /data/backup/borg/${config.networking.hostName} 770 borgmatic borgmatic - -"
    "D /var/lib/borgmatic 770 borgmatic borgmatic - -"
    "D /var/lib/borgmatic/backup 770 borgmatic borgmatic - -"
    "D /var/lib/borgmatic/log 770 borgmatic borgmatic - -"
    "D /var/lib/borgmatic/cache 770 borgmatic borgmatic - -"
  ];
}
