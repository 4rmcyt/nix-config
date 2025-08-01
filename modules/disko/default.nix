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
                # Corrected: Removed the invalid "/boot" string from this list
                mountOptions = [ "fmask=0137" "dmask=0027" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "/@root" = { mountpoint = "/"; mountOptions = [ "compress=zstd" "noatime" ]; };
                  "/@home" = { mountpoint = "/home"; mountOptions = [ "compress=zstd" "noatime" ]; };
                  "/@nix" = { mountpoint = "/nix"; mountOptions = [ "compress=zstd" "noatime" ]; };
                  "/@log" = { mountpoint = "/var/log"; mountOptions = [ "compress=zstd" "noatime" ]; };
                  "/@swap" = { mountpoint = "/.swapvol"; mountOptions = [ "noatime" ]; };
                };
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
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "/@data" = { mountpoint = "/data"; mountOptions = [ "compress=zstd" "noatime" ]; };
                };
              };
            };
          };
        };
      };
    };
  };

  swapDevices = [{ device = "/.swapvol/swapfile"; size = 16384; }];
}
