# Disko configuration for Huawei MateBook D14 WAQ9BR
# Standard layout: EFI boot + root partition + swap file
# Adjust device path if your NVMe device is different
_: {
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-WDC_PC_SN730_SDBPNTY-512G-1027_20230H445703"; # Verify with 'lsblk' before installing!
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "2G";
              # Your actual EFI partition size
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "noatime"
                  "umask=0077"
                ];
              };
            };
            root = {
              size = "100%";
              # Rest of disk
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [
                  "defaults"
                  "noatime"
                  "commit=60"
                  "errors=remount-ro"
                ];
              };
            };
          };
        };
      };
    };
  };

  # Swap file configuration (16GB for hibernation support)
  swapDevices = [
    {
      device = "/swapfile";
      size = 16384; # 16GB in MB
      options = [ "discard" ]; # TRIM swap pages on NVMe
    }
  ];
}
