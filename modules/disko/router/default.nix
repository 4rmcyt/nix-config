# Disko layout for Sophos SG110/120 — legacy BIOS, single HDD/SSD.
#
# PLACEHOLDER: replace device with output of:
#   lsblk -d -o NAME,SIZE,MODEL
# then use /dev/disk/by-id/... for stability.
#
# Layout: MBR → GRUB partition (1M) → ext4 root (100%)
# No swap partition — zramSwap handles it in software (see default.nix).
_: {
  disko.devices.disk.main = {
    type   = "disk";
    device = "/dev/disk/by-id/PLACEHOLDER";  # replace after lsblk on hardware
    content = {
      type = "mbrTable";
      partitions = {
        grub = {
          size = "1M";
          type = "EF02";  # BIOS boot partition for GRUB
          priority = 1;
        };
        root = {
          size    = "100%";
          content = {
            type       = "filesystem";
            format     = "ext4";
            mountpoint = "/";
            mountOptions = [ "defaults" "noatime" "errors=remount-ro" ];
          };
        };
      };
    };
  };
}
