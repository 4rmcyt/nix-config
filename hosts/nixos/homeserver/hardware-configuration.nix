{ config, lib, pkgs, modulesPath, ... }:
{
  # =================================================================
  # 1. Imports & Global Settings
  # =================================================================
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Enable firmware updates for devices like CPUs and SSDs.
  hardware = {
    enableRedistributableFirmware = lib.mkDefault true;
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    graphics = {
      enable = true;
      extraPackages = with pkgs;
        [
          intel-ocl
          libva-vdpau-driver
          vaapiVdpau
          intel-vaapi-driver
          intel-media-driver # For VAAPI (decoding/encoding)
          intel-compute-runtime # For OpenCL (compute/filtering)
        ];
    };
    bluetooth.enable = false;
    i2c.enable = true;
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
  # =================================================================
  # 2. Boot & Filesystem Configuration
  # =================================================================
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        edk2-uefi-shell.enable = true;
        configurationLimit = 20;
        editor = false;
        timeout = 3;
      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_xanmod_stable;
    supportedFilesystems = [
      "vfat"
      "zfs"
    ];
    initrd.availableKernelModules = [
      "ahci"
      "nvme"
      "usb_storage"
      "usbhid"
      "xhci_pci"
    ];
    zfs = {
      devNodes = "/dev/disk/by-id/";
      forceImportAll = true;
    };
    kernelModules = [
      "coretemp"
      "fuse"
      "kvm-intel"
      "iTCO_wdt"
    ];
    kernelParams = [
      "zfs.zfs_arc_max=12884901888"
      "i915.enable_guc=2"
    ];
  };

  # =================================================================
  # 4. Hardware & Power Management
  # =================================================================
  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "performance";
    powertop.enable = true;
  };

  # =================================================================
  # 5. System Services
  # =================================================================
  services = {
    fwupd.enable = true;
    zfs = {
      autoScrub.enable = true;
      autoScrub.interval = "monthly";
      autoSnapshot.enable = false;
      trim.enable = true;
      trim.interval = "weekly";
    };
    smartd = {
      enable = true;
      defaults.autodetected = "-a -o on -s (S/../.././02|L/../../7/04)";
      devices = [
        { device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX0K543315"; }
        { device = "/dev/disk/by-id/ata-Patriot_P210_1024GB_P210EDCB23011109345"; }
      ];
    };
    pipewire.enable = false;
    pulseaudio.enable = false;
    xserver.enable = false;
    displayManager.gdm.enable = false;
    desktopManager.gnome.enable = false;
    blueman.enable = false;
    geoclue2.enable = false;
    printing.enable = false;
    thermald.enable = lib.mkDefault true;
  };
  systemd.oomd.enable = true;
  programs.auto-cpufreq = {
    enable = true;
    settings = {
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
  };
  systemd.coredump.enable = false;
}