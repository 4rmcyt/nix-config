{ lib, ... }:

{
  disko.devices = {
    disk = {
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
                mountOptions = [
                  "fmask=0137"
                  "dmask=0027"
                ];
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
      rpool = {
        type = "zpool";
        options.ashift = "12";
        rootFsOptions = {
          compression = "zstd";
          atime = "off";
          xattr = "sa";
          acltype = "posixacl";
        };
        datasets = {
          "root" = {
            type = "zfs_fs";
            mountpoint = "/";
          };
          "home" = {
            type = "zfs_fs";
            mountpoint = "/home";
          };
          "nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options."com.sun:auto-snapshot" = "false";
          };
          "var/log" = {
            type = "zfs_fs";
            mountpoint = "/var/log";
          };
          "var/lib" = {
            type = "zfs_fs";
            mountpoint = "/var/lib";
          };
          "reserved" = {
            type = "zfs_fs";
            mountpoint = "none";
            options.reservation = "5G";
          };
        };
      };

      dpool = {
        type = "zpool";
        options.ashift = "12";
        rootFsOptions = {
          compression = "zstd";
          atime = "off";
          xattr = "sa";
          acltype = "posixacl";
        };
        datasets = {
          "data" = {
            type = "zfs_fs";
            mountpoint = "/data";
          };
        };
      };
    };

    swap = {
      zfs_swap = {
        type = "swap";
        zfs_pool = "rpool";
        size = "16G";
      };
    };
  };
}
