# GCP e2-micro (2 vCPU / 1 GB RAM / 30 GB disk), us-central1.
# Boot device: /dev/sda (virtio-scsi). GPT layout: 1M BIOS boot + ext4 root.
# nixos-anywhere + disko handle partitioning — this file is minimal.
{
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot = {
    initrd.availableKernelModules = [
      "virtio_pci"
      "virtio_scsi"
      "virtio_blk"
      "virtio_net"
      "9p"
      "9pnet_virtio"
      "sd_mod"
      "ata_piix"
    ];
    initrd.kernelModules = [];
    kernelModules = [];
    extraModulePackages = [];
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Facter report — populated after first nixos-anywhere deploy
  # facter.reportPath = ./facter.json;

  hardware.enableRedistributableFirmware = lib.mkDefault true;
  services.qemuGuest.enable = true;

  networking.useDHCP = lib.mkDefault true;
}
