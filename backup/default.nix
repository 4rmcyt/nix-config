{
  pkgs,
  config,
  lib,
  ...
}: {
  # Ensure the PostgreSQL backup directory exists
  services.postgresqlBackup = {
    enable = true;
    compression = "zstd";
    backupAll = true;
    location = "/var/lib/postgres-backup";
  };

  services.borgmatic = {
    enable = true;

    # Define base settings that apply to all backup configurations
    settings = {
      source_directories = [
        "/home/zeev"
        "/var/log"
        "/var/lib/postgres-backup" # Directory for PostgreSQL dumps
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

      retention = {
        keep_hourly = 6;
        keep_daily = 7;
        keep_weekly = 4;
        keep_monthly = 6;
        keep_yearly = 1;
      };

      consistency = {
        checks = ["repository" "archives"];
        check_last = 10;
      };
    };

    # Define a specific backup job/configuration
    configurations = {
      # The name here becomes the .yaml filename in /etc/borgmatic.d/
      local-server-backup = {
        repository = "/var/lib/borgmatic/${config.networking.hostName}";
        # Add the hook to initialize the repository
        hooks = {
          before = [
            "borg init --encryption=repokey-blake2"
          ];
        };
      };
    };
  };

  # Ensure the necessary directories exist with correct permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/borgmatic/${config.networking.hostName} 750 borgmatic borgmatic -"
    "d /var/lib/postgres-backup 0750 postgres postgres -"
  ];
}