# /etc/nixos/disko.nix
{ lib,... }:

{
  disko.devices = {
    disk = {
      # The fast NVMe SSD for the OS (/dev/nvme0n1)
      nvme = {
        device = "/dev/disk/by-id/SAMSUNG_MZVLW256HEHP-000L7_S35ENX0J520898"; # Using by-id is more robust
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
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                mountOptions = [ "compress=zstd" "noatime" ];
                subvolumes = {
                  "/@" = {
                    mountpoint = "/";
                  };
                  "/@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/@swap" = {
                    mountpoint = "/.swapvol";
                    swap.swapfile.size = "16G";
                  };
                };
              };
            };
          };
        };
      };

      # The larger SATA SSD for home directories (/dev/sda)
      sata = {
        device = "/dev/disk/by-id/ata-Patriot_P210_1024GB_PAA00121122080500123"; # Using by-id is more robust
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            home = {
              size = "100%";
              content = {
                type = "btrfs";
                mountOptions = [ "compress=zstd" "noatime" ];
                subvolumes = {
                  "/@home" = {
                    mountpoint = "/home";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}