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

      ssd = {
        type = "disk";
        device = "/dev/disk/by-id/ata-Patriot_P210_1024GB_P210EDCB23011109345";
        content = {
          type = "gpt";
          partitions = {
            DATA = {
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
        };
        options = {
          ashift = "12";
          autotrim = "off";
        };
        datasets = {
          # zfs uses cow free space to delete files when the disk is completely filled
          "reserved" = {
            options = {
              canmount = "off";
              mountpoint = "none";
              reservation = "20G";
            };
            type = "zfs_fs";
          };
          "nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              atime = "off";
              canmount = "on";
              "com.sun:auto-snapshot" = "false";
            };
            postCreateHook = "zfs snapshot zroot/nix@empty";
          };
          # Where everything else lives, and is wiped on reboot by restoring a blank zfs snapshot.
          "root" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            options."com.sun:auto-snapshot" = "false";
            mountpoint = "/";
          };
          "home" = {
            type = "zfs_fs";
            options."com.sun:auto-snapshot" = "false";
            mountpoint = "/home";
            postCreateHook = "zfs snapshot zroot/home@empty";
          };
          "log" = {
            type = "zfs_fs";
            options = {
              "com.sun:auto-snapshot" = "false";
              # Required for systemd-journald to set per-user ACLs on journal
              # files (avoids "Failed to set ACL … Operation not supported")
              acltype = "posixacl";
              xattr = "sa";
            };
            mountpoint = "/var/log";
          };
          "postgresql" = {
            type = "zfs_fs";
            options."com.sun:auto-snapshot" = "false";
            mountpoint = "/var/lib/postgresql";
            options."recordsize" = "16K";
            postCreateHook = "zfs snapshot zroot/postgresql@empty";
          };
          "containers" = {
            type = "zfs_fs";
            options = {
              acltype = "posixacl";
              "com.sun:auto-snapshot" = "false";
            };
            mountpoint = "/var/lib/containers";
          };
          "authentik" = {
            type = "zfs_fs";
            options."com.sun:auto-snapshot" = "false";
            mountpoint = "/var/lib/private/authentik";
          };
          "vaultwarden" = {
            type = "zfs_fs";
            options."com.sun:auto-snapshot" = "false";
            mountpoint = "/var/lib/vaultwarden";
            postCreateHook = "zfs snapshot zroot/vaultwarden@empty";
          };
          "data" = {
            type = "zfs_fs";
            options."com.sun:auto-snapshot" = "false";
            options.sync = "disabled";
            mountpoint = "/data";
          };
        };
      };
    };
  };
}
