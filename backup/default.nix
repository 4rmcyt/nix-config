{
  pkgs,
  config,
  lib,
  ...
}:
let
  yamlFormat = pkgs.formats.yaml { };
  borgmatic-config = {
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
      "/etc"
    ];
    exclude_patterns = [
      # Home directory excludes
      "/home/zeev/Downloads"
      "/home/zeev/backups"
      "/home/zeev/.cache"
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
    encryption_passcommand = "${pkgs.coreutils}/bin/cat ${config.sops.secrets.borgmatic_encryption_pass.path}";
    ssh_command = "ssh -i ${config.sops.secrets.borg_ssh_key.path}";
    keep_hourly = 6;
    keep_daily = 7;
    keep_weekly = 4;
    keep_monthly = 6;
    keep_yearly = 1;

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
  };
  srv-borgbackup-config = {
    repositories = [
      {
        label = "On Disk Backup";
        path = "/var/lib/borgmatic/backup/${config.networking.hostName}";
      }
      {
        label = "Hetzner Server Backup";
        path = "ssh://u478963@u478963.your-storagebox.de:23/backup/${config.networking.hostName}";
      }
    ];
    hooks = {
      before_backup = {
        commands = [
          "echo Starting a backup job."
          "${pkgs.iputils}/bin/ping -q -c 1 10.100.100.5 > /dev/null || exit 75"
        ];
      };
      after_backup = {
        commands = [
          "echo Backup created."
        ];
      };
      on_error = {
        commands = [
          "echo Error while creating a backup."
        ];
      };
    };
  };
in

{
  services.postgresqlBackup = {
    enable = true;
    compression = "zstd";
    backupAll = true;
    location = "/var/lib/postgres-backup/dump.sql";
  };

  services.borgmatic = {
    enable = true;

  };
  environment.etc."borgmatic/base/borgmatic_base.yaml".source =
    yamlFormat.generate "borgmatic_base.yaml" borgmatic-config;
  environment.etc."borgmatic.d/srv-borgbackup.yaml".source =
    yamlFormat.generate "srv-borgbackup.yaml" srv-borgbackup-config;

  systemd.tmpfiles.rules = [
    "d /var/lib/borgmatic/backup 750 borgmatic borgmatic -"

  ];
}
