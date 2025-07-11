{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.systemd-boot.configurationLimit = 10;

  networking.useDHCP = lib.mkDefault false; # We use static IP in networking.nix

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.graphics.enable = true;

  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-vaapi-driver
    vaapiIntel
    vaapiVdpau
    intel-compute-runtime
    libvdpau-va-gl
  ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  services.fwupd.enable = true;

  systemd.tmpfiles.rules = [
    "z /boot 0755 root root - -"
    "z /boot/loader 0700 root root - -"
    "z /boot/loader/random-seed 0600 root root - -"
  ];

  boot.loader.systemd-boot.editor = false; # Disable boot editor
  boot.loader.timeout = 3; # Reduce boot timeout
}
