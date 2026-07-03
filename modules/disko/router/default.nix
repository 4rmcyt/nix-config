# Disko layout for Sophos SG110/120 — legacy BIOS, single HDD/SSD.
#
# Disk: Hitachi HTS543225A7A384 232.9G (sda)
#
# Layout: MBR → GRUB partition (1M) → ext4 root (100%)
# No swap partition — zramSwap handles it in software (see default.nix).
_: {
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02"; # BIOS boot partition for GRUB
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = ["defaults" "noatime" "errors=remount-ro"];
          };
        };
      };
    };
  };
}
