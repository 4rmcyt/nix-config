{ lib, ... }:

{
  disko.devices = {
    disk = {
      # The fast NVMe SSD for the OS (/dev/nvme0n1)
      nvme = {
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX0J520898"; # Fixed: nvme- prefix
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
                mountOptions = [ "defaults" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Force creation
                subvolumes = {
                  "/@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/@log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/@swap" = {
                    mountpoint = "/.swapvol";
                    mountOptions = [ "noatime" ];
                    # Fixed: Proper swap configuration
                  };
                };
              };
            };
          };
        };
      };

      # The larger SATA SSD for home directories (/dev/sda)
      sata = {
        device = "/dev/disk/by-id/ata-Patriot_P210_1024GB_PAA00121122080500123";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            home = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Force creation
                subvolumes = {
                  "/@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/@media" = {
                    mountpoint = "/home/zeev/media";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/@downloads" = {
                    mountpoint = "/home/zeev/downloads";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Configure swap file separately
  swapDevices = [
    {
      device = "/.swapvol/swapfile";
      size = 16384; # 16GB in MB
    }
  ];

  # Additional filesystem configurations
  fileSystems = {
    "/" = {
      options = [ "compress=zstd" "noatime" ];
    };
    "/nix" = {
      options = [ "compress=zstd" "noatime" ];
    };
    "/home" = {
      options = [ "compress=zstd" "noatime" ];
    };
  };
}