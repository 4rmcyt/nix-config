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
      # NVMe drive for OS and services
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
        datasets = {
          "root"    = { type = "zfs_fs"; mountpoint = "/"; };
          "home"    = { type = "zfs_fs"; mountpoint = "/home"; };
          "nix"     = { type = "zfs_fs"; mountpoint = "/nix"; options."com.sun:auto-snapshot" = "false"; };
          "var/log" = { type = "zfs_fs"; mountpoint = "/var/log"; };
          "var/lib" = { type = "zfs_fs"; mountpoint = "none"; };
          "var/lib/postgresql" = { type = "zfs_fs"; mountpoint = "/var/lib/postgresql"; };
          "var/lib/containers" = { type = "zfs_fs"; mountpoint = "/var/lib/containers"; };
          "var/lib/redis-authentik" = { type = "zfs_fs"; mountpoint = "/var/lib/redis-authentik"; };
          "var/lib/redis-paperless" = { type = "zfs_fs"; mountpoint = "/var/lib/redis-paperless"; };
          "var/lib/redis-redis" = { type = "zfs_fs"; mountpoint = "/var/lib/redis-redis"; };
          "var/lib/postgres-backup" = { type = "zfs_fs"; mountpoint = "/var/lib/postgres-backup"; };
          "var/lib/paperless" = { type = "zfs_fs"; mountpoint = "/var/lib/paperless"; };
          "var/lib/home-assistant" = { type = "zfs_fs"; mountpoint = "/var/lib/home-assistant"; };
          "var/lib/microbin" = { type = "zfs_fs"; mountpoint = "/var/lib/microbin"; };
          "var/lib/ldap" = { type = "zfs_fs"; mountpoint = "/var/lib/ldap"; };
          "var/lib/authentik" = { type = "zfs_fs"; mountpoint = "/var/lib/authentik"; };
          "var/lib/vaultwarden" = { type = "zfs_fs"; mountpoint = "/var/lib/vaultwarden"; };
          "var/lib/grafana" = { type = "zfs_fs"; mountpoint = "/var/lib/grafana"; };
          "var/lib/prometheus2" = { type = "zfs_fs"; mountpoint = "/var/lib/prometheus2"; };
          "var/lib/acme" = { type = "zfs_fs"; mountpoint = "/var/lib/acme"; };
          "var/lib/nginx" = { type = "zfs_fs"; mountpoint = "/var/lib/nginx"; };
          "reserved" = {
            type = "zfs_fs";
            mountpoint = "none";
            options.reservation = "10G";
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

    # ✅ Define the ZFS Volume for swap here, as shown in the official example
    zfs_vol = {
      "rpool/swap" = {
        size = "16G";
        content = {
          type = "swap";
          randomUUID = true;
        };
      };
    };
  };
}