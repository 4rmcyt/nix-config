{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  # =================================================================
  # 1. Imports
  # =================================================================
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  # =================================================================
  # 2. Boot Configuration
  # =================================================================
  boot = {
    # Kernel configuration - CachyOS kernel optimized for stability
    # Using standard variant as server variant has same features
    kernelPackages = pkgs.linuxPackages_cachyos;
    zfs.package = pkgs.zfs_cachyos;

    # Kernel modules
    initrd.availableKernelModules = [
      "ahci"
      "nvme"
      "usb_storage"
      "usbhid"
      "xhci_pci"
    ];

    kernelModules = [
      "coretemp"
      "fuse"
      "iTCO_wdt"
      "kvm-intel"
    ];

    # Kernel parameters
    kernelParams = [
      "i915.enable_guc=2"
      "zfs.zfs_arc_max=12884901888"
    ];

    # Boot loader configuration
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 20;
        edk2-uefi-shell.enable = true;
        editor = false;
      };
      timeout = 3;
    };

    # Filesystem support
    supportedFilesystems = [
      "vfat"
      "zfs"
    ];

    # ZFS configuration
    zfs = {
      devNodes = "/dev/disk/by-id/";
      forceImportAll = true;
    };
  };

  # =================================================================
  # 3. Hardware Configuration
  # =================================================================
  hardware = {
    # Hardware features
    bluetooth.enable = false;
    i2c.enable = true;

    # CPU & firmware
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableRedistributableFirmware = lib.mkDefault true;

    # Graphics
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        # intel-compute-runtime # For OpenCL (compute/filtering)
        intel-media-driver # For VAAPI (decoding/encoding)
        intel-ocl
        intel-vaapi-driver
        libva-vdpau-driver
      ];
    };
  };

  # =================================================================
  # 4. Environment Variables
  # =================================================================
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  # =================================================================
  # 5. Power Management
  # =================================================================
  power.ups.package = pkgs.nut;

  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "performance";
    powertop.enable = true;
  };

  # =================================================================
  # 6. Services
  # =================================================================
  services = {
    # System services
    fwupd.enable = true;
    thermald.enable = lib.mkDefault true;

    # Hardware monitoring
    smartd = {
      enable = true;
      defaults.autodetected = "-a -o on -s (S/../.././02|L/../../7/04)";
      # Auto-detect all NVMe and SATA devices
      autodetect = true;
    };

    # ZFS services
    zfs = {
      autoScrub = {
        enable = false;
        interval = "monthly";
      };
      autoSnapshot.enable = false;
      trim = {
        enable = false;
        interval = "weekly";
      };
    };
  };

  # =================================================================
  # 7. Systemd Configuration
  # =================================================================
  systemd = {
    coredump.enable = false;
    oomd.enable = true;
  };
}
