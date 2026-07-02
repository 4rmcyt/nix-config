# Sophos SG110/120 hardware configuration.
# Intel Atom D525 (Bonnell), 2 GB RAM, legacy BIOS.
#
# PLACEHOLDER: real interface names must be filled in after running
#   nixos-generate-config on the physical hardware and inspecting `ip link`.
# Replace wanInterface / lanTrunkInterface values in networking.nix.
{
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot = {
    # Atom D525 is a 32-bit-capable 64-bit CPU; standard x86_64 kernel is fine.
    initrd.availableKernelModules = [
      "ahci"
      "ata_piix"
      "ehci_pci"
      "pata_marvell"
      "sd_mod"
      "uhci_hcd"
      "usb_storage"
    ];

    kernelModules = ["kvm-intel" "8021q"];

    # Serial console for out-of-band recovery when network config is broken.
    # Sophos SG1xx uses ttyS0 at 115200 baud.
    kernelParams = [
      "console=ttyS0,115200n8"
      "console=tty0"
    ];

    loader = {
      # Legacy BIOS — use GRUB, not systemd-boot.
      grub = {
        enable = true;
        # PLACEHOLDER: set to the boot disk device, e.g. "/dev/sda"
        device = lib.mkDefault "/dev/sda";
        configurationLimit = 10;
      };
      timeout = 3;
    };

    kernel.sysctl = {
      # IP forwarding — required for router operation.
      "net.ipv4.ip_forward" = 1;
      "net.ipv4.conf.all.forwarding" = 1;
      # Disable IPv6 forwarding (IPv4-only homelab).
      "net.ipv6.conf.all.forwarding" = 0;
      "net.ipv6.conf.all.disable_ipv6" = 1;
      "net.ipv6.conf.default.disable_ipv6" = 1;
    };
  };

  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault true;
    enableRedistributableFirmware = lib.mkDefault true;
  };

  # PLACEHOLDER: set to the boot disk after nixos-generate-config on real hardware.
  fileSystems."/" = {
    device = lib.mkDefault "/dev/sda1";
    fsType = "ext4";
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  environment.systemPackages = with pkgs; [
    ethtool
    iproute2
    nftables
    tcpdump
  ];
}
