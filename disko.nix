{ lib, ... }:

{
  disko.devices = {
    # This 'disk' attribute set is required for your version
    disk = {
      # The fast NVMe SSD for the OS (/dev/nvme0n1)
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
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
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
                  };
                };
              };
            };
          };
        };
      };

      # The larger SATA SSD for home directories (/dev/sda)
      sata = {
        device = "/dev/disk/by-id/ata-Patriot_P210_1024GB_P210EDCB23011109345";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            home = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
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

  # The rest of your configuration is correct
  swapDevices = [
    {
      device = "/.swapvol/swapfile";
      size = 16384;
    }
  ];

  fileSystems."/" = { options = [ "compress=zstd" "noatime" ]; };
  fileSystems."/nix" = { options = [ "compress=zstd" "noatime" ]; };
  fileSystems."/home" = { options = [ "compress=zstd" "noatime" ]; };
}