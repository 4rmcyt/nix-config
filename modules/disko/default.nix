{ lib, ... }:

let
  zfsOptions = {
    compression = "zstd";
    atime = "off";
    xattr = "sa";
    acltype = "posixacl";
  };
in
{
  disko.devices = {
    disk = {
      # NVMe drive for OS, services, and swap
      nvme = {
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX0K543315";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };

      # SATA drive for additional data
      sata = {
        device = "/dev/disk/by-id/ata-Patriot_P210_1024GB_P210EDCB23011109345";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            data = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "dpool";
              };
            };
          };
        };
      };
    };

    zpool = {
      # Root pool (rpool) on the fast NVMe drive
      rpool = {
        type = "zpool";
        rootFsOptions = zfsOptions;

        # Filesystems on rpool
        datasets = {
          "root"    = { type = "zfs_fs"; mountpoint = "/"; };
          "home"    = { type = "zfs_fs"; mountpoint = "/home"; };
          "nix"     = { type = "zfs_fs"; mountpoint = "/nix"; options."com.sun:auto-snapshot" = "false"; };
          "var/log" = { type = "zfs_fs"; mountpoint = "/var/log"; };
          "var/lib" = { type = "zfs_fs"; mountpoint = "none"; };
          "var/lib/postgresql" = { type = "zfs_fs"; mountpoint = "/var/lib/postgresql"; };
          "var/lib/containers" = { type = "zfs_fs"; mountpoint = "/var/lib/containers"; };
          # ... (and all your other var/lib datasets)
        };

        # Volumes (for swap, etc.) on rpool ✅
        volumes = {
          "swap" = {
            size = "16G";
            content = {
              type = "swap";
              randomUUID = true;
            };
          };
        };
      };

      # Data pool (dpool) on the larger SATA drive
      dpool = {
        type = "zpool";
        rootFsOptions = zfsOptions;
        datasets = {
          "data" = { type = "zfs_fs"; mountpoint = "/data"; };
          "data/media/.state" = { type = "zfs_fs"; mountpoint = "/data/media/.state"; };
        };
      };
    };
  };
}