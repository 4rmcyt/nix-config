{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  # Find the latest ZFS-compatible kernel
  # Prefer LTS kernel for server stability, otherwise use latest compatible kernel
  zfsCompatibleKernelPackages =
    lib.filterAttrs (
      name: kernelPackages:
        (builtins.match "linux_(lts|[0-9]+_[0-9]+)" name)
        != null
        && (builtins.tryEval kernelPackages).success
        && kernelPackages ? ${config.boot.zfs.package.kernelModuleAttribute}
        && !(kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken or true)
    )
    pkgs.linuxKernel.packages;

  # Sort and get the latest compatible kernel, preferring LTS
  latestKernelPackage = let
    ltsKernel = lib.attrByPath ["linux_lts"] null pkgs.linuxKernel.packages;
    ltsCompatible =
      ltsKernel
      != null
      && (builtins.tryEval ltsKernel).success
      && ltsKernel ? ${config.boot.zfs.package.kernelModuleAttribute}
      && !(ltsKernel.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken or true);
  in
    if ltsCompatible
    then ltsKernel
    else
      lib.last (
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
    # Use latest ZFS-compatible kernel (prefers LTS for server stability)
    # Automatically selects LTS kernel if ZFS supports it, otherwise latest compatible
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
      "wireguard"
    ];

    # Kernel parameters
    kernelParams = [
      # Intel GPU optimizations
      "i915.enable_guc=3" # GuC firmware and HuC authentication

      # ZFS ARC
      "zfs.zfs_arc_max=13421772800" # 12.5GB (40% of 32GB RAM)

      # CPU isolation
      "nohz_full=1-7" # Updated to match 8-core CPU
      "rcu_nocbs=1-7"
      "isolcpus=1-7"
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

    extraModprobeConfig = ''
      # Intel iGPU GuC/HuC firmware
      options i915 enable_guc=3

      # ZFS performance tuning
      # Increase txg timeout to reduce sync frequency (default: 5s)
      options zfs zfs_txg_timeout=30

      # Increase dirty data limit to allow more write coalescing
      # Default is 10% of ARC, increase to 20% for better write performance
      options zfs zfs_dirty_data_max_percent=20

      # Async write tuning - allow more pending writes
      options zfs zfs_vdev_async_write_min_active=2
      options zfs zfs_vdev_async_write_max_active=10

      # Reduce metadata overhead
      options zfs metaslab_debug_load=0
    '';

    # System control parameters
    kernel.sysctl = {
      # Kernel optimizations for server
      "kernel.nmi_watchdog" = 0;

      # VM/Memory optimizations for 32GB RAM
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_ratio" = 15;
      "vm.dirty_background_ratio" = 5;

      # ZFS-specific
      "vm.min_free_kbytes" = 524288; # 512MB min free

      # Network optimizations for server
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_max" = 16777216;
      "net.ipv4.tcp_rmem" = "4096 87380 16777216";
      "net.ipv4.tcp_wmem" = "4096 65536 16777216";
      "net.ipv4.tcp_fastopen" = 3;
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };

  # =================================================================
  # 3. Hardware Configuration
  # =================================================================
  hardware = {
    # Hardware features
    bluetooth.enable = false;
    i2c.enable = true;
    enableAllFirmware = true;

    # CPU & firmware
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableRedistributableFirmware = lib.mkDefault true;

    # Graphics
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        # intel-vaapi-driver
        intel-media-driver
        intel-compute-runtime-legacy1
        ocl-icd
      ];
    };
  };

  # =================================================================
  # 4. Environment Variables & System Packages
  # =================================================================
  environment = {
    sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };

    # System packages
    systemPackages = with pkgs; [
      clinfo # For testing OpenCL
    ];
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

    # SCX Scheduler (disabled - conflicts with CPU isolation)
    # Use default CFS scheduler with isolated CPUs instead
    scx.enable = false;

    # Hardware monitoring
    smartd = {
      enable = true;
      defaults.autodetected = "-a -o on -s (S/../.././02|L/../../7/04)";
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
