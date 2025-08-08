{
  disko.devices = {
    disk = {
      nvme = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX0K543315";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "system";
              };
            };
          };
        };
      };
      sata = {
        type = "disk";
        device = "/dev/disk/by-id/ata-Patriot_P210_1024GB_P210EDCB23011109345";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "data"; 
              };
            };
          };
        };
      };
    };
    zpool = {
      system = {
        type = "zpool";
        rootFsOptions = {
          mountpoint = "none";
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
        };
        options.ashift = "12";

        datasets = {
          "root" = { type = "zfs_fs"; mountpoint = "/"; };
          "root/nix" = { type = "zfs_fs"; mountpoint = "/nix"; };
          "root/home" = { type = "zfs_fs"; mountpoint = "/home"; };
          "root/var" = { type = "zfs_fs"; mountpoint = "/var"; };
          "root/var/log" = { type = "zfs_fs"; mountpoint = "/var/log"; };
          "root/var/lib" = { type = "zfs_fs"; mountpoint = "none"; };
          "root/var/lib/postgresql" = { type = "zfs_fs"; mountpoint = "/var/lib/postgresql"; options.recordsize = "16k"; };
          "root/var/lib/containers" = { type = "zfs_fs"; mountpoint = "/var/lib/containers"; };
          "root/var/lib/redis-authentik" = { type = "zfs_fs"; mountpoint = "/var/lib/redis-authentik"; };
          "root/var/lib/redis-paperless" = { type = "zfs_fs"; mountpoint = "/var/lib/redis-paperless"; };
          "root/var/lib/redis-redis" = { type = "zfs_fs"; mountpoint = "/var/lib/redis-redis"; };
          "root/var/lib/postgres-backup" = { type = "zfs_fs"; mountpoint = "/var/lib/postgres-backup"; };
          "root/var/lib/paperless" = { type = "zfs_fs"; mountpoint = "/var/lib/paperless"; };
          "root/var/lib/home-assistant" = { type = "zfs_fs"; mountpoint = "/var/lib/home-assistant"; };
          "root/var/lib/microbin" = { type = "zfs_fs"; mountpoint = "/var/lib/microbin"; };
          "root/var/lib/ldap" = { type = "zfs_fs"; mountpoint = "/var/lib/ldap"; };
          "root/var/lib/authentik" = { type = "zfs_fs"; mountpoint = "/var/lib/authentik"; };
          "root/var/lib/vaultwarden" = { type = "zfs_fs"; mountpoint = "/var/lib/vaultwarden"; };
          "root/var/lib/grafana" = { type = "zfs_fs"; mountpoint = "/var/lib/grafana"; };
          "root/var/lib/prometheus2" = { type = "zfs_fs"; mountpoint = "/var/lib/prometheus2"; };
          "root/var/lib/acme" = { type = "zfs_fs"; mountpoint = "/var/lib/acme"; };
          "root/var/lib/nginx" = { type = "zfs_fs"; mountpoint = "/var/lib/nginx"; };

          "root/reserved" = {
            type = "zfs_fs";
            mountpoint = "none";
            options.reservation = "12G";
          };
          "root/swap" = {
            type = "zfs_volume";
            size = "16G";
            content = { type = "swap"; };
            options = {
              volblocksize = "4k";
              compression = "zle";
              logbias = "throughput";
              sync = "always";
              primarycache = "metadata";
              secondarycache = "none";
              "com.sun:auto-snapshot" = "false";
            };
          };
        };
      };

      data = {
        type = "zpool";
        rootFsOptions = { canmount = "off"; };
        datasets = {
          "data" = { type = "zfs_fs"; mountpoint = "/data"; };
          "data/media" = { type = "zfs_fs"; mountpoint = "/data/media"; options.recordsize = "1M"; };
          "data/media/movies" = { type = "zfs_fs"; mountpoint = "/data/media/movies"; };
          "data/media/shows" = { type = "zfs_fs"; mountpoint = "/data/media/shows"; };
          "data/media/music" = { type = "zfs_fs"; mountpoint = "/data/media/music"; };
          "data/media/audiobooks" = { type = "zfs_fs"; mountpoint = "/data/media/audiobooks"; };
          "data/media/books" = { type = "zfs_fs"; mountpoint = "/data/media/books"; };
          "data/media/comics" = { type = "zfs_fs"; mountpoint = "/data/media/comics"; };
          "data/media/manga" = { type = "zfs_fs"; mountpoint = "/data/media/manga"; };
          "data/media/torrents" = { type = "zfs_fs"; mountpoint = "/data/media/torrents"; };
          "data/media/usenet" = { type = "zfs_fs"; mountpoint = "/data/media/usenet"; };
          "data/media/.state" = { type = "zfs_fs"; mountpoint = "/data/media/.state"; };
          "data/Downloads" = { type = "zfs_fs"; mountpoint = "/data/Downloads"; };
        };
      };
    };
  };
}