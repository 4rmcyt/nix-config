{
  pkgs,
  config,
  lib,
  ...
}:
let
  prepareEnvScript = pkgs.writeShellScript "prepare-borgmatic-env" ''
    mkdir -p /root/.ssh
    ${pkgs.openssh}/bin/ssh-keyscan -p 23 u478963.your-storagebox.de >> /root/.ssh/known_hosts
    chmod 600 /root/.ssh/known_hosts
  '';
in
{

  services.borgmatic = {
  enable = true;
  settings = {
    # No changes needed for sources, excludes, repositories,
    # encryption, ssh_command, compression, retention, etc.
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
    repositories = [
      {
        label = "On Disk Backup";
        path = "/data/backup/borg/${config.networking.hostName}";
      }
      {
        label = "Hetzner Server Backup";
        path = "ssh://u478963@u478963.your-storagebox.de:23/./borg/hostname/${config.networking.hostName}";
      }
    ];
    encryption_passcommand = "${pkgs.coreutils}/bin/cat ${config.sops.secrets.borgmatic_encryption_pass.path}";
    ssh_command = "ssh -i ${config.sops.secrets.borg_private_key.path} -o UserKnownHostsFile=${config.sops.secrets.knownHosts.path}";
    compression = "zstd";
    archive_name_format = "backup-{now:%Y-%m-%dT%H:%M:%S.%f}";
    relocated_repo_access_is_ok = true;
    keep_hourly = 24;
    keep_daily = 7;
    keep_weekly = 4;
    keep_monthly = 12;
    keep_yearly = 3;

      
      # Hooks
      hooks = {
      before_configuration = [
        {
          run = [
            "echo 'Starting backup job.'"
            "${pkgs.iputils}/bin/ping -q -c 1 192.168.1.254 > /dev/null"
          ];
        }
      ];

      after_configuration = [
        {
          states = [ "finish" ];
          run = [ "echo 'Backup job completed successfully.'" ];
        }
      ];
      
      # Runs if any error occurs during the process.
      on_error = [
        {
          run = [ "echo 'CRITICAL: A backup job failed.'" ];
        }
      ];
    };

      
      # # Consistency Checks
      # checks = [
      #   {
      #     name = "repository";
      #     frequency = "always";
      #   }
      #   {
      #     name = "archives";
      #     frequency = "always";
      #   }
      #   {
      #     name = "data";
      #     frequency = "always";
      #   }
      #   {
      #     name = "extract";
      #     frequency = "always";
      #   }
      # ];
      # check_last = 3;

      # Notifications
      # uptime_kuma = {
      #   push_url = "https://kuma.example.com/api/push/borgmatic";
      #   states = [
      #     "start"
      #     "finish"
      #     "fail"
      #   ];
      # };
    };
  };
  users.users.borgmatic = {
    isSystemUser = true;
    group = "borgmatic";
    extraGroups = [ "users" "media" ];
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

