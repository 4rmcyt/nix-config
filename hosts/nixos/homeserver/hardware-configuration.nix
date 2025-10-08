{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
  ) pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in
{
  # =================================================================
  # 1. Imports
  # =================================================================
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # =================================================================
  # 2. Boot Configuration
  # =================================================================
  boot = {
    # Boot loader configuration
    loader = {
      systemd-boot = {
        enable = true;
        edk2-uefi-shell.enable = true;
        configurationLimit = 20;
        editor = false;
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    # Kernel configuration
    kernelPackages = latestKernelPackage;
    supportedFilesystems = [
      "vfat"
      "zfs"
    ];

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
    # CPU & firmware
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableRedistributableFirmware = lib.mkDefault true;

    # Graphics
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-compute-runtime # For OpenCL (compute/filtering)
        intel-media-driver # For VAAPI (decoding/encoding)
        intel-ocl
        intel-vaapi-driver
        libva-vdpau-driver
        vaapiVdpau
      ];
    };

    # Hardware features
    bluetooth.enable = false;
    i2c.enable = true;
  };

  # =================================================================
  # 4. Power Management
  # =================================================================
  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "performance";
    powertop.enable = true;
  };

  power.ups.package = pkgs.nut;

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
    # Hardware monitoring
    smartd = {
      enable = true;
      defaults.autodetected = "-a -o on -s (S/../.././02|L/../../7/04)";
      devices = [
        { device = "/dev/disk/by-id/ata-Patriot_P210_1024GB_P210EDCB23011109345"; }
        { device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX0K543315"; }
      ];
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

    # System services
    fwupd.enable = true;
    thermald.enable = lib.mkDefault true;

    # Disabled services
    blueman.enable = false;
    desktopManager.gnome.enable = false;
    displayManager.gdm.enable = false;
    geoclue2.enable = false;
    pipewire.enable = false;
    printing.enable = false; # CUPS printing
    pulseaudio.enable = false;
    xserver.enable = false;
  };

  # =================================================================
  # 7. Systemd Configuration
  # =================================================================
  systemd = {
    coredump.enable = false;
    oomd.enable = true;
  };
}
