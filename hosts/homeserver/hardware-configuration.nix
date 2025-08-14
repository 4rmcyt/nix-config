{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  # =================================================================
  # 1. Imports & Global Settings
  # =================================================================
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Enable firmware updates for devices like CPUs and SSDs.
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # =================================================================
  # 2. Boot & Filesystem Configuration
  # =================================================================
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.edk2-uefi-shell.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20;
  boot.loader.systemd-boot.editor = false;
  boot.loader.timeout = 3;

  # Define filesystem support and ZFS settings for the initial ramdisk (initrd).
  boot.kernelPackages = pkgs.linuxPackages_xanmod_stable;
  boot.supportedFilesystems = [
    "vfat"
    "zfs"
  ];

  # Define kernel modules needed early in the boot process.
  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "usb_storage"
    "usbhid"
    "xhci_pci"
  ];

  # =================================================================
  # 3. Kernel Configuration
  # =================================================================

  boot.zfs = {
    devNodes = "/dev/disk/by-id/";
    forceImportAll = true;
  };

  # Kernel modules to load at boot.
  boot.kernelModules = [
    "coretemp"
    "fuse"
    "kvm-intel"
    "iTCO_wdt"
  ];

  boot.kernelParams = [ "zfs.zfs_arc_max=12884901888" ];

  # =================================================================
  # 4. Hardware & Power Management
  # =================================================================
  hardware.cpu.intel.updateMicrocode = true;
  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = with pkgs; [
    intel-compute-runtime
    intel-media-driver
    intel-ocl
    libvdpau-va-gl
    vaapiVdpau
  ];

  hardware.bluetooth.enable = false;
  hardware.i2c.enable = true;

  powerManagement.enable = true;
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  powerManagement.powertop.enable = true;

  # =================================================================
  # 5. System Services
  # =================================================================
  services.fwupd.enable = true;
  systemd.oomd.enable = true;
  services.auto-cpufreq.enable = true;

  services.smartd = {
    enable = true;
    defaults.autodetected = "-a -o on -s (S/../.././02|L/../../7/04)";
    devices = [
      { device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX0K543315"; }
      { device = "/dev/disk/by-id/ata-Patriot_P210_1024GB_P210EDCB23011109345"; }
    ];
  };

  services.zfs = {
    autoScrub.enable = true;
    autoScrub.interval = "monthly";
    autoSnapshot.enable = false;
    trim.enable = true;
    trim.interval = "weekly";
  };

  services = {
    pipewire.enable = false;
    pulseaudio.enable = false;
    xserver.enable = false;
    displayManager.gdm.enable = false;
    desktopManager.gnome.enable = false;
    blueman.enable = false;
    geoclue2.enable = false;
    printing.enable = false; # CUPS printing
    ucodenix = {
      enable = true;
      cpuModelId = "000906ED"; # Or config.facter.reportPath if specified
    };
  };
  systemd.coredump.enable = false;
}
