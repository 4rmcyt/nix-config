{
  disko.devices = {
    disk = {
      nvme = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_S6S1NS0W101791N";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              label = "EFI";
              name = "ESP";
              size = "2048M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "umask=0077"
                ];
              };
            };
            ZFS = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
    };

    zpool = {
      zroot = {
        type = "zpool";
        rootFsOptions = {
          canmount = "off";
          checksum = "edonr";
          compression = "zstd";
          dnodesize = "auto";
          mountpoint = "none";
          normalization = "formD";
          relatime = "on";
          "com.sun:auto-snapshot" = "false";
          "sync" = "standard";
          "logbias" = "throughput";
          "primarycache" = "all";
          "secondarycache" = "all";
          "zfs_txg_timeout" = "30";
        };
        options = {
          ashift = "12";
          autotrim = "on";
        };
        datasets = {
          # Reserve space for ZFS operations
          "reserved" = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
              reservation = "10G";
            };
          };

          # Root filesystem - ephemeral
          "root" = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
              atime = "off";
              "com.sun:auto-snapshot" = "false";
            };
            mountpoint = "/";
            postCreateHook = "zfs snapshot zroot/root@blank";
          };

          # Nix store
          "nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              atime = "off";
              canmount = "on";
              "com.sun:auto-snapshot" = "false";
            };
          };

          # Home directories - persistent
          "home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options = {
              atime = "off";
              "com.sun:auto-snapshot" = "false";
            };
          };

          # System logs
          "log" = {
            type = "zfs_fs";
            mountpoint = "/var/log";
            options = {
              "com.sun:auto-snapshot" = "false";
            };
          };

          # Gaming data (Steam, etc.)
          "games" = {
            type = "zfs_fs";
            mountpoint = "/home/games";
            options = {
              recordsize = "1M"; # Better for large game files
              "com.sun:auto-snapshot" = "false";
            };
          };

          # VM/Container storage
          "vms" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/libvirt";
            options = {
              recordsize = "64K";
              "com.sun:auto-snapshot" = "false";
            };
          };
        };
      };
    };
  };
}
