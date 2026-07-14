{
  disko.devices = {
    disk = {
      nvme = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_S6S1NS0W101791N";
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
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [
                  "-L"
                  "nixos"
                  "-f"
                ];
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = [
                      "compress=zstd:1"
                      "noatime"
                      "ssd"
                      "discard=async"
                      "space_cache=v2"
                    ];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd:1"
                      "noatime"
                      "ssd"
                      "discard=async"
                      "space_cache=v2"
                      "nodatacow"
                    ];
                  };
                  "/log" = {
                    mountpoint = "/var/log";
                    mountOptions = [
                      "compress=zstd:1"
                      "noatime"
                      "ssd"
                      "discard=async"
                      "space_cache=v2"
                    ];
                  };
                  "/home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "compress=zstd:1"
                      "noatime"
                      "ssd"
                      "discard=async"
                      "space_cache=v2"
                    ];
                  };
                  "/games" = {
                    mountpoint = "/home/games";
                    mountOptions = [
                      "compress=zstd:1"
                      "noatime"
                      "ssd"
                      "discard=async"
                      "space_cache=v2"
                    ];
                  };
                  "/vms" = {
                    mountpoint = "/var/lib/libvirt";
                    mountOptions = [
                      "compress=zstd:1"
                      "noatime"
                      "ssd"
                      "discard=async"
                      "space_cache=v2"
                    ];
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
