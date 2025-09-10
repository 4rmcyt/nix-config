{
  config,
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}:
{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../../modules/disko/desktop
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [
    "kvm-amd"
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
  boot.extraModulePackages = [ ];

  # ZFS configuration with CachyOS ZFS
  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs = {
      requestEncryptionCredentials = true;
      forceImportRoot = false;
      package = inputs.chaotic.packages.${pkgs.system}.zfs_cachyos;
    };
    kernelParams = [
      "nvidia-drm.modeset=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];
  };

  # ZFS filesystems
  fileSystems."/" = {
    device = "rpool/root";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "rpool/home";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/XXXX-XXXX"; # Replace with your actual UUID
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ ];

  # NVIDIA Hardware Configuration
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false; # Use proprietary driver
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  # Services for ZFS
  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "weekly";
    };
    autoSnapshot = {
      enable = true;
      flags = "-k -p --utc";
      frequent = 4;
      hourly = 24;
      daily = 7;
      weekly = 4;
      monthly = 12;
    };
  };

  # NVIDIA environment variables
  environment.variables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  # Enables DHCP on each ethernet and wireless interface
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
