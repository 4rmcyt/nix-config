{ lib, ... }:

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
        # Added recommended pool properties for performance and compatibility
        rootFsOptions = {
          compression = "zstd";
          atime = "off";
          xattr = "sa";
          acltype = "posixacl";
        };
        datasets = {
          # System datasets
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

          # Parent dataset for service data (not mounted itself)
          "var/lib" = {
            type = "zfs_fs";
            mountpoint = "none";
          };

          # Dedicated datasets for specific services
          "var/lib/postgresql" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/postgresql";
          };
          "var/lib/containers" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/containers";
          };
          "var/lib/redis-authentik" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/redis-authentik";
          };
          "var/lib/redis-paperless" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/redis-paperless";
          };
          "var/lib/redis-redis" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/redis-redis";
          };
          "var/lib/postgres-backup" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/postgres-backup";
          };
          "var/lib/paperless" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/paperless";
          };
          "var/lib/home-assistant" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/home-assistant";
          };
          "var/lib/microbin" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/microbin";
          };
          "var/lib/ldap" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/ldap";
          };
          "var/lib/authentik" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/authentik";
          };
          "var/lib/vaultwarden" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/vaultwarden";
          };
          "var/lib/grafana" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/grafana";
          };
          "var/lib/prometheus2" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/prometheus2";
          };
          "var/lib/acme" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/acme";
          };
          "var/lib/nginx" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/nginx";
          };
          "var/lib/loki" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/loki";
          };
          "data/media/.state" = {
            type = "zfs_fs";
            mountpoint = "/data/media/.state";
          };
          "data/backup" = {
            type = "zfs_fs";
            mountpoint = "/data/backup";
          };
          "data/media" = {
            type = "zfs_fs";
            mountpoint = "/data/media";
          };

          # Safety net dataset for emergencies
          "reserved" = {
            type = "zfs_fs";
            mountpoint = "none";
            options.reservation = "10G"; # Reserve 10GB of space
          };
        };
      };

      # Data pool (dpool) on the larger SATA drive
      dpool = {
        type = "zpool";
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

    # Swap definition on a ZFS volume (zvol)
    swap = {
      zfs_swap = {
        type = "swap";
        zfs_pool = "rpool";
        size = "16G";
      };
    };
  };
}

# {
#   disko.devices = {
#     disk = {
#       # Add proper disk identification and validation
#       main = {
#         type = "disk";
#         device = "/dev/disk/by-id/nvme-specific-identifier";  # Use specific IDs
#         content = {
#           type = "gpt";
#           partitions = {
#             ESP = {
#               size = "1G";
#               type = "EF00";
#               content = {
#                 type = "filesystem";
#                 format = "vfat";
#                 mountpoint = "/boot";
#                 mountOptions = [
#                   "defaults"
#                   "umask=0077"    # Secure boot partition
#                   "dmask=0077"
#                   "fmask=0177"
#                   "nodev"
#                   "nosuid"
#                   "noexec"
#                 ];
#               };
#             };

#             # Add swap partition with encryption
#             swap = {
#               size = "8G";
#               content = {
#                 type = "swap";
#                 randomEncryption = true;  # Encrypt swap
#                 priority = 100;
#               };
#             };

#             zfs = {
#               size = "100%";
#               content = {
#                 type = "zfs";
#                 pool = "rpool";
#               };
#             };
#           };
#         };
#       };
#     };

#     zpool = {
#       rpool = {
#         type = "zpool";
#         # Add ZFS security options
#         options = {
#           ashift = "12";
#           autotrim = "on";
#         };

#         # Root dataset with encryption
#         rootFsOptions = {
#           encryption = "aes-256-gcm";
#           keyformat = "passphrase";
#           keylocation = "prompt";

#           # Security options
#           acltype = "posixacl";
#           compression = "zstd";
#           dnodesize = "auto";
#           normalization = "formD";
#           relatime = "on";
#           xattr = "sa";

#           # Performance options
#           recordsize = "1M";
#           primarycache = "all";
#           secondarycache = "all";
#         };

#         datasets = {
#           # System datasets
#           "root" = {
#             type = "zfs_fs";
#             mountpoint = "/";
#             options = {
#               mountpoint = "/";
#               # Security: no setuid on root
#               setuid = "off";
#               devices = "off";
#             };
#           };

#           "home" = {
#             type = "zfs_fs";
#             mountpoint = "/home";
#             options = {
#               mountpoint = "/home";
#               setuid = "off";  # No setuid in home
#               exec = "on";     # Allow execution in home
#             };
#           };

#           # Separate dataset for var with stricter options
#           "var" = {
#             type = "zfs_fs";
#             mountpoint = "/var";
#             options = {
#               mountpoint = "/var";
#               setuid = "off";
#               devices = "off";
#               exec = "off";    # No execution in /var
#             };
#           };
#         };
#       };
#     };
#   };
# }
