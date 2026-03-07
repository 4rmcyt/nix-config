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
      "video=eDP-1:d"

      # ZFS ARC
      "zfs.zfs_arc_max=13421772800" # 12.5GB (40% of 32GB RAM)

      # CPU isolation
      "nohz_full=1-7" # Updated to match 8-core CPU
      "rcu_nocbs=1-7"
      "isolcpus=1-7"

      # Raise hung task timeout to avoid false positives from ZFS / k3s I/O
      "hung_task_timeout_secs=300"
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
      extraPools = ["zdata"];
    };

    # Import zbackup post-boot so a missing/broken SSD never blocks startup
    postBootCommands = ''
      ${pkgs.zfs}/bin/zpool import -N -d /dev/disk/by-id zbackup 2>/dev/null || true
      ${pkgs.zfs}/bin/zfs mount zbackup/backup 2>/dev/null || true
    '';

    extraModprobeConfig = ''
      # Intel iGPU GuC/HuC firmware
      options i915 enable_guc=3

      # ZFS performance tuning
      # Use default txg timeout (5s) — 30s causes massive blocking syncs
      options zfs zfs_txg_timeout=5

      # More concurrent I/O operations (NixOS NAS recommendation)
      options zfs zfs_vdev_max_active=3000

      # Increase dirty data limit to allow more write coalescing
      options zfs zfs_dirty_data_max_percent=25

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

    # System packages (hardware monitoring & management)
    systemPackages = with pkgs; [
      apcupsd
      auto-cpufreq
      clinfo
      cpuid
      fwupd
      intel-gpu-tools
      libva-utils
      lm_sensors
      microcode-intel
      powertop
      prometheus-apcupsd-exporter
      rasdaemon
      smartmontools
      zfs
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

  # =================================================================
  # 8. MCE & Reliability
  # =================================================================

  # Enable rasdaemon to properly decode and handle MCE (Machine Check Exception)
  # events. The MCE errors logged at TSC=0 (Banks 10–13, ADDR ~0xFEF1D500) are
  # stale BIOS-generated events in the MMIO region logged before OS handoff —
  # rasdaemon decodes them and records them in a structured SQLite database
  # instead of leaving raw hex in dmesg.
  hardware.rasdaemon.enable = true;

  # Journald: reduce I/O pressure to prevent watchdog timeouts under ZFS load
  services.journald.extraConfig = ''
    Storage=persistent
    RateLimitIntervalSec=30s
    RateLimitBurst=10000
    SystemMaxUse=2G
    RuntimeMaxUse=200M
  '';

  # Journal ACL: set acltype=posixacl on the ZFS log dataset so journald can
  # grant per-user read access via POSIX ACLs.  The disko config now declares
  # these options for fresh installs; this oneshot applies them to the already-
  # existing dataset on the running system (idempotent — zfs set is safe to
  # repeat).
  systemd.services.zfs-log-acl = {
    description = "Set POSIX ACL support on ZFS log dataset";
    wantedBy = ["local-fs.target"];
    after = ["zfs-import-zroot.service"];
    requires = ["zfs-import-zroot.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.zfs}/bin/zfs set acltype=posixacl xattr=sa zroot/log";
    };
  };

  # Keep zeev in systemd-journal as belt-and-suspenders (allows fallback
  # group-based access if ACLs are unavailable for any reason).
  users.users.zeev.extraGroups = ["systemd-journal"];
}
