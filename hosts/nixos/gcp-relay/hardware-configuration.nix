# GCP e2-micro (2 vCPU / 1 GB RAM / 30 GB disk), us-central1.
# Boots via nixpkgs' google-compute-image.nix (hosts/nixos/gcp-relay/default.nix),
# not disko — GCE provisions and partitions the disk itself, so this file is minimal.
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
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.enableRedistributableFirmware = lib.mkDefault true;
  services.qemuGuest.enable = true;

  networking.useDHCP = lib.mkDefault true;
}
