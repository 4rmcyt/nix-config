{
  config,
  pkgs,
  lib,
  ...
}:
{

  services.borgmatic = {
    enable = true;
    configurations = {
      server = {
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
            path = "ssh://u478963@u478963.your-storagebox.de:23/./borg/hostname/${config.networking.hostName}";
            label = "remote";
          }
          {
            path = "/data/backup/borg";
            label = "hdd";
          }
        ];

      };
    };

    storage = {
      encryptionPasscommand = "${pkgs.coreutils}/bin/cat $${config.sops.secrets.borgmatic_encryption_pass.path}";
      extraConfig = {
        ssh_command = "ssh -i ${config.sops.secrets.borg_private_key.path}";
        compression = "zstd";
      };
    };

    retention = {
      keepHourly = 12;
      keepDaily = 14;
      keepWeekly = 8;
      keepMonthly = 6;
      keepYearly = 3;
    };

    # consistency = {
    #   checks = [
    #     {
    #       name = "repository";
    #       frequency = "2 weeks";
    #     }
    #     {
    #       name = "archives";
    #       frequency = "6 weeks";
    #     }
    #     #{
    #     #  name = "data";
    #     #  frequency = "12 weeks";
    #     #}
    #     {
    #       name = "extract";
    #       frequency = "12 weeks";
    #     }
    #   ];
    # };
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

# Notifications
# uptime_kuma = {
#   push_url = "https://kuma.labhome.work/api/push/borgmatic";
#   states = [
#     "start"
#     "finish"
#     "fail"
#   ];
# };
#   systemd.tmpfiles.rules = [
#     "D /data/backup/borg/${config.networking.hostName} 770 borgmatic borgmatic - -"
#     "D /var/lib/borgmatic 770 borgmatic borgmatic - -"
#     "D /var/lib/borgmatic/backup 770 borgmatic borgmatic - -"
#     "D /var/lib/borgmatic/log 770 borgmatic borgmatic - -"
#     "D /var/lib/borgmatic/cache 770 borgmatic borgmatic - -"
#   ];
# }
