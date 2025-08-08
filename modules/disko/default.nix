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
        datasets = {
          root = {
            type = "zfs_fs";
            mountpoint = "/";
          };
          home = {
            type = "zfs_fs";
            mountpoint = "/home";
          };
          nix = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options."com.sun:auto-snapshot" = "false";
          };
          var = {
            type = "zfs_fs";
            mountpoint = "none";
            children = {
              log = {
                type = "zfs_fs";
                mountpoint = "/var/log";
              };
              lib = {
                type = "zfs_fs";
                mountpoint = "none";
                children = {
                  postgresql = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/postgresql";
                  };
                  containers = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/containers";
                  };
                  redis-authentik = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/redis-authentik";
                  };
                  redis-paperless = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/redis-paperless";
                  };
                  redis-redis = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/redis-redis";
                  };
                  postgres-backup = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/postgres-backup";
                  };
                  paperless = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/paperless";
                  };
                  home-assistant = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/home-assistant";
                  };
                  microbin = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/microbin";
                  };
                  ldap = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/ldap";
                  };
                  authentik = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/authentik";
                  };
                  vaultwarden = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/vaultwarden";
                  };
                  grafana = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/grafana";
                  };
                  prometheus2 = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/prometheus2";
                  };
                  acme = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/acme";
                  };
                  nginx = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/nginx";
                  };
                  loki = {
                    type = "zfs_fs";
                    mountpoint = "/var/lib/loki";
                  };
                };
              };
            };
          };
          zfs_swap = {
            type = "zfs_volume";
            size = "16G";
            content = {
              type = "swap";
            };
            options = {
              volblocksize = "4096";
              compression = "zle";
              logbias = "throughput";
              sync = "always";
              primarycache = "metadata";
              secondarycache = "none";
              "com.sun:auto-snapshot" = "false";
            };
          };
          "data" = {
            type = "zfs_fs";
            mountpoint = "none";
            children = {
              "media" = {
                type = "zfs_fs";
                mountpoint = "none";
                children = {
                  ".state" = {
                    type = "zfs_fs";
                    mountpoint = "/data/media/.state";
                  };
                };
              };
            };
          };
        };
      };

      # Data pool (dpool) on the larger SATA drive
      dpool = {
        type = "zpool";
        rootFsOptions = zfsOptions;
        datasets = {
          data = {
            type = "zfs_fs";
            mountpoint = "/data";
          };
        };
      };
    };
  };
}
