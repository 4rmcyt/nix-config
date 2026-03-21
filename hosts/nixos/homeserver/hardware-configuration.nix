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
        (builtins.match "linux_(lts|[0-9]+_[0-9]+)" name)
        != null
        && (builtins.tryEval kernelPackages).success
        && kernelPackages ? ${config.boot.zfs.package.kernelModuleAttribute}
        && !(kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken or true)
    )
    pkgs.linuxKernel.packages;

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
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot = {
    kernelPackages = latestKernelPackage;

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

    kernelParams = [
      "i915.enable_guc=3"
      "video=eDP-1:d"
      "zfs.zfs_arc_max=13421772800" # 12.5GB
      "nohz_full=1-7"
      "rcu_nocbs=1-7"
      "isolcpus=1-7"
      "hung_task_timeout_secs=300"
    ];

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

    supportedFilesystems = ["vfat" "zfs"];

    zfs = {
      devNodes = "/dev/disk/by-id/";
      forceImportAll = true;
      extraPools = ["zdata"];
    };

    postBootCommands = ''
      ${pkgs.zfs}/bin/zpool import -N -d /dev/disk/by-id zbackup 2>/dev/null || true
      ${pkgs.zfs}/bin/zfs mount zbackup/backup 2>/dev/null || true
    '';

    extraModprobeConfig = ''
      options i915 enable_guc=3
      options zfs zfs_txg_timeout=5
      options zfs zfs_vdev_max_active=3000
      options zfs zfs_dirty_data_max_percent=25
      options zfs zfs_vdev_async_write_min_active=2
      options zfs zfs_vdev_async_write_max_active=10
      options zfs metaslab_debug_load=0
    '';

    kernel.sysctl = {
      "kernel.nmi_watchdog" = 0;
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_ratio" = 15;
      "vm.dirty_background_ratio" = 5;
      "vm.min_free_kbytes" = 524288;
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_max" = 16777216;
      "net.ipv4.tcp_rmem" = "4096 87380 16777216";
      "net.ipv4.tcp_wmem" = "4096 65536 16777216";
      "net.ipv4.tcp_fastopen" = 3;
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };

  hardware = {
    bluetooth.enable = false;
    i2c.enable = true;
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableRedistributableFirmware = lib.mkDefault true;
    rasdaemon.enable = true;

    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-compute-runtime-legacy1
        ocl-icd
      ];
    };
  };

  environment = {
    sessionVariables.LIBVA_DRIVER_NAME = "iHD";

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
      msr-tools
      powertop
      prometheus-apcupsd-exporter
      rasdaemon
      smartmontools
      zfs
    ];
  };

  power.ups.package = pkgs.nut;

  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "performance";
    powertop.enable = true;
  };

  services = {
    fwupd.enable = true;
    thermald.enable = lib.mkDefault true;
    scx.enable = false;

    smartd = {
      enable = true;
      defaults.autodetected = "-a -o on -s (S/../.././02|L/../../7/04)";
      autodetect = true;
    };

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

    journald.extraConfig = ''
      Storage=persistent
      RateLimitIntervalSec=30s
      RateLimitBurst=10000
      SystemMaxUse=2G
      SystemKeepFree=500M
      MaxRetentionSec=3month
      RuntimeMaxUse=200M
    '';
  };

  systemd = {
    coredump.enable = false;
    oomd.enable = true;

    services.rasdaemon.serviceConfig.StandardError = "null";
    services.rasdaemon.serviceConfig.StandardOutput = "null";

    services.zfs-log-acl = {
      description = "Set POSIX ACL support on ZFS log dataset";
      wantedBy = ["zfs.target"];
      after = ["zfs.target"];
      requires = ["zfs.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.zfs}/bin/zfs set acltype=posixacl xattr=sa zroot/log";
      };
    };
  };

  users.users.zeev.extraGroups = ["systemd-journal"];
}
