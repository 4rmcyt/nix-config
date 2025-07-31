{
  pkgs,
  config,
  lib,
  ...
}:
{

  services.borgmatic = {
    enable = true;
    settings = {
      # Sources
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
      # Excludes
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
      exclude_if_present = [
        ".nobackup"
        ".stversions"
        ".thumbnails"
      ];

      # Repositories
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
      encryption_passcommand = "${pkgs.coreutils}/bin/cat ${config.sops.secrets.borgmatic_encryption_pass.path}";
      ssh_command = "ssh -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=${config.sops.secrets.knownHosts.path} -o StrictHostKeyChecking=yes -i ${config.sops.secrets.borg_ssh_key.path} ";
      compression = "zstd";
      archive_name_format = "backup-{now}";
      relocated_repo_access_is_ok = true;

      # Retention
      keep_hourly = 24;
      keep_daily = 7;
      keep_weekly = 4;
      keep_monthly = 12;
      keep_yearly = 3;

      hooks = {
        commands = {
          before_create = [
            "echo Starting a backup job."
            "${pkgs.iputils}/bin/ping -q -c 1 192.168.1.254 > /dev/null || exit 75"
          ];
          after_create = [
            "echo Backup created."
          ];
          on_error = [
            "echo Error while creating a backup."
          ];
        };
      };

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
      uptime_kuma = {
        push_url = "https://kuma.example.com/api/push/borgmatic";
        states = [
          "start"
          "finish"
          "fail"
        ];
      };
    };
  };
  users.users.borgmatic = {
    isSystemUser = true;
    group = "borgmatic";
    extraGroups = [ "users" ];
  };
  users.groups.borgmatic = { };

  systemd.tmpfiles.rules = [
    "dR /var/lib/borgmatic/backup 770 borgmatic borgmatic -   -"
  ];
}
