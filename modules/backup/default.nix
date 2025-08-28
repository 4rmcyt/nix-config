# TODO use ZnapZend!
{
  config,
  pkgs,
  ...
}:
{
  sops.secrets = {
    borg_private_key = {
      sopsFile = ../../secrets/system.yaml;
      key = "borg_private_key";
      owner = config.users.users.root.name;
      group = config.users.groups.backup.name;
      mode = "0440";
    };
    borgmatic_encryption_pass = {
      sopsFile = ../../secrets/borgmatic.yaml;
      key = "borgmatic_encryption_pass";
      owner = config.users.users.root.name;
      group = config.users.groups.backup.name;
      mode = "0440";
    };
  };
  services.postgresqlBackup = {
    enable = true;
    compression = "zstd";
    backupAll = true;
    location = "/var/lib/postgres-backup"; # Directory, not file
    startAt = "*-*-* 02:00:00"; # Run before borgmatic
  };
  services.borgmatic = {
    enable = true;
    settings = {
      # Sources
      source_directories = [
        "/var/lib/acme" # SSL certificates
        "/var/lib/tailscale" # VPN state
        "/var/lib/NetworkManager" # Network configs
        "/var/lib/systemd"
        "/home/zeev"
        "/var/lib/postgres-backup"
        "/var/lib/home-assistant"
        "/var/lib/kavita"
        "/var/lib/miniflux"
        "/var/lib/mosquitto"
        "/var/lib/paperless"
        "/var/lib/radicale"
        "/var/lib/sops"
        "/var/lib/calibre-web"
        "/var/lib/grafana"
        "/var/lib/homepage-dashboard"
        "/var/lib/nixos"
        "/var/lib/authentik"
        "/var/lib/uptime-kuma"
        "/var/lib/vaultwarden/data" # Actual vault data
        "/var/lib/vaultwarden/config"
        "/data/.secret"
        "/data/media/.state"
        "/etc"
      ];
      # Excludes
      exclude_patterns = [
        # User-specific excludes
        "/home/zeev/Downloads"
        "/home/zeev/backups"
        "/home/zeev/.cache"
        "/home/zeev/.npm/_cacache"
        "/home/zeev/.local/share/Trash"
        "/home/zeev/.mozilla/firefox/*/Cache*"
        "/home/zeev/.thunderbird/*/ImapMail/*/INBOX"
        "/home/zeev/snap/*/common/.cache"
        "/var/lib/systemd/coredump"
        "/var/lib/systemd/catalog"
        "/var/lib/systemd/journal"
        "/var/lib/systemd/rfkill"

        # Add more comprehensive patterns
        "**/.cache"
        "**/.tmp"
        "**/tmp"
        "**/temp"
        "**/Cache"
        "**/cache"
        "**/node_modules"
        "**/venv"
        "**/.venv"
        "**/target" # Rust builds
        "**/build" # Build directories
        "**/dist" # Distribution directories
        "**/__pycache__" # Python cache
        "**/*.pyc" # Python bytecode
        "**/.git" # Git repositories (usually)
        "**/.svn" # SVN repositories

        # System excludes
        "/var/lib/containers"
        "/var/lib/flatpak"
        "/var/lib/docker"
        "/var/lib/podman"
        "/var/cache"
        "/var/tmp"
        "/tmp"
        "/proc"
        "/sys"
        "/dev"
        "/run"
        "/mnt"
        "/media"

        # Service-specific large files
        "/var/lib/jellyfin/transcodes"
        "/var/lib/jellyfin/cache"
        "/var/lib/plex/Library/Application Support/Plex Media Server/Cache"
        "/var/lib/grafana/plugins" # Can be reinstalled
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
          path = "ssh://u478963@u478963.your-storagebox.de:23/./borg/${config.networking.hostName}";
        }
      ];
      encryption_passcommand = "${pkgs.coreutils}/bin/cat ${config.sops.secrets.borgmatic_encryption_pass.path}";
      ssh_command = "ssh -i " + config.sops.secrets.borg_private_key.path;

      # Backup Settings
      compression = "zstd,11";
      archive_name_format = "backup-{now}";
      relocated_repo_access_is_ok = true;

      # Retention
      keep_within = "1d"; # Keep all backups within last day
      keep_hourly = 24; # Last 24 hours
      keep_daily = 30; # Last 30 days (increased from 7)
      keep_weekly = 12; # Last 12 weeks (increased from 4)
      keep_monthly = 24; # Last 24 months (increased from 12)
      keep_yearly = 5;

      # Hooks
      before_backup = [
        "echo Starting backup job at $(date)"
        "${pkgs.iputils}/bin/ping -q -c 1 192.168.1.165 > /dev/null || exit 75"
        # Stop services that need consistent state
        "${pkgs.systemd}/bin/systemctl stop miniflux.service || true"
        "${pkgs.systemd}/bin/systemctl stop home-assistant.service || true"
        # Wait for services to stop gracefully
        "sleep 10"
      ];
      after_backup = [
        "echo Backup created."
        # Restart services
        "${pkgs.systemd}/bin/systemctl start home-assistant.service || true"
        "${pkgs.systemd}/bin/systemctl start miniflux.service || true"
      ];
      on_error = [ "echo Error while creating a backup." ];

      # Consistency Checks
      checks = [
        {
          name = "repository";
          frequency = "always";
        }
        {
          name = "archives";
          frequency = "2 weeks";
        }
        {
          name = "data";
          frequency = "1 month";
        }
        {
          name = "extract";
          frequency = "3 months";
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
  systemd.services.borgmatic = {
    serviceConfig = {
      ReadWritePaths = [ "/data/backup/borg" ];
      TimeoutStartSec = "0";
    };
  };
  systemd.tmpfiles.rules = [
    "D /data/backup/borg 700 root root - -"
    "D /data/backup/borg/homeserver 700 root root - -"
    "D /var/lib/borgmatic 750 root backup - -"
    "D /var/lib/borgmatic/backup 750 root backup - -"
    "D /var/lib/borgmatic/log 750 root backup - -"
    "D /var/lib/borgmatic/cache 750 root backup - -"
  ];
  users.groups.backup = { };
}
