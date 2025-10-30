{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  zfsCompatibleKernelPackages =
    lib.filterAttrs (
      name: kernelPackages:
        (builtins.match "linux_[0-9]+_[0-9]+" name)
        != null
        && (builtins.tryEval kernelPackages).success
        && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
    )
    pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in {
  # =================================================================
  # 1. Imports
  # =================================================================
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  # =================================================================
  # 2. Boot Configuration
  # =================================================================
  boot = {
    # Kernel configuration
    kernelPackages = latestKernelPackage;

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
  # 4. Power Management
  # =================================================================
  power.ups.package = pkgs.nut;

  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "performance";
    powertop.enable = true;
  };

  # =================================================================
  # 5. Environment Variables
  # =================================================================
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
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
