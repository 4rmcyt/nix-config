# Disko configuration for Huawei MateBook D14 WAQ9BR
# Standard layout: EFI boot + swap + root partition
# Adjust device path if your NVMe device is different

{...}: {
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1"; # Verify with 'lsblk' before installing!
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
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
            swap = {
              size = "16G"; # Increased for hibernation support (2x RAM)
              content = {
                type = "swap";
                randomEncryption = true;
                resumeDevice = true;
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [
                  "defaults"
                  "noatime"
                  "errors=remount-ro"
                ];
              };
            };
          };
        };
      };
    };
  };
}