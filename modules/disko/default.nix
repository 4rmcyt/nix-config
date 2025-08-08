{
  disko.devices = {
    one = {
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
          luks = lib.mkIf cfg.zfs.root.encrypt {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted1";
              settings.allowDiscards = true;
              passwordFile = "/tmp/secret.key";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
          notluks = lib.mkIf (!cfg.zfs.root.encrypt) {
            size = "100%";
            content = {
              type = "zfs";
              pool = "zroot";
            };
          };
        };
      };
    };
    two = {
      type = "disk";
      device = "/dev/disk/by-id/ata-Patriot_P210_1024GB_P210EDCB23011109345";
      content = {
        type = "gpt";
        partitions = {
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted2";
              settings.allowDiscards = true;
              passwordFile = "/tmp/secret.key";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
    };
  };
  zpool = {
      zroot = {
        type = "zpool";
        mode = mkIf cfg.zfs.root.mirror "mirror";
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
          autotrim = "on";
        };
        datasets = {
          # zfs uses cow free space to delete files when the disk is completely filled
          reserved = {
            options = {
              canmount = "off";
              mountpoint = "none";
              reservation = "20G";
            };
            type = "zfs_fs";
          };
          # nixos-anywhere currently has issues with impermanence so agenix keys are lost during the install process.
          # as such we give /etc/ssh its own zfs dataset rather than using impermanence to save the keys when we wipe the root directory on boot
          # not needed if you don't use agenix or don't use nixos-anywhere to install
          etcssh = {
            type = "zfs_fs";
            mountpoint = "/etc/ssh";
            options."com.sun:auto-snapshot" = "false";
            postCreateHook = "zfs snapshot zroot/etcssh@empty";
          };          
          nix = {
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
          root = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            options."com.sun:auto-snapshot" = "false";
            mountpoint = "/";
            postCreateHook = ''
                zfs snapshot zroot/root@empty
            '';
          home = {
            type = "zfs_fs";
            options."com.sun:auto-snapshot" = "false";
            mountpoint = "/home";
            postCreateHook = "zfs snapshot zroot/home@empty";
          };
          var = {
            type = "zfs_fs";
            options."com.sun:auto-snapshot" = "false";
            mountpoint = "/var";
            postCreateHook = "zfs snapshot zroot/var@empty";
          };
          postgresql = {
            type = "zfs_fs";
            options."com.sun:auto-snapshot" = "false";
            mountpoint = "/var/lib/postgresql";
            options."recordsize" = "16K";
            postCreateHook = "zfs snapshot zroot/postgresql@empty";
          };
          containers = {
            type = "zfs_fs";
            options."com.sun:auto-snapshot" = "false";
            mountpoint = "/var/lib/containers";
            postCreateHook = "zfs snapshot zroot/containers@empty";
          };
          authentik = {
            type = "zfs_fs";
            options."com.sun:auto-snapshot" = "false";
            mountpoint = "/var/lib/authentik";
            postCreateHook = "zfs snapshot zroot/authentik@empty";
          };
          vaultwarden = {
            type = "zfs_fs";
            options."com.sun:auto-snapshot" = "false";
            mountpoint = "/var/lib/vaultwarden";
            postCreateHook = "zfs snapshot zroot/vaultwarden@empty";
          };
          data = {
            type = "zfs_fs";
            options."com.sun:auto-snapshot" = "false";
            mountpoint = "/data";
            postCreateHook = "zfs snapshot zroot/data@empty";
          };
        };
      };
    }
  };
}
