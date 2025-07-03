{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Boot configuration
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "kvm-intel" ];  # Change to "kvm-amd" for AMD
  boot.extraModulePackages = [ ];

  # File systems are handled by disko.nix - DO NOT DEFINE THEM HERE
  # The disko.nix configuration will create:
  # - Root filesystem (/)
  # - Boot filesystem (/boot)
  # - Swap file
  
  # Remove all fileSystems and swapDevices definitions
  # as they conflict with disko configuration

  # Network configuration
  networking.useDHCP = lib.mkDefault false;  # We use static IP in networking.nix

  # Hardware platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  
  # CPU microcode updates
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # For AMD systems, use instead:
  # hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Hardware acceleration for media services (Jellyfin)
  hardware.opengl = {
    enable = true;
    # Remove deprecated driSupport options
  };

  # Enable hardware acceleration drivers
  hardware.opengl.extraPackages = with pkgs; [
    intel-media-driver  # For Intel graphics
    vaapiIntel
    vaapiVdpau
    libvdpau-va-gl
  ];

  # Power management
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  # Enable firmware updates
  services.fwupd.enable = true;
}