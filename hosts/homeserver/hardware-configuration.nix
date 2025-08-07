{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  hardware.enableRedistributableFirmware = lib.mkDefault true;
  # 1. Boot Loader Configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.systemd-boot.editor = false;
  boot.loader.timeout = 3;

  # 2. Kernel & Initrd Configuration
  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "usb_storage"
    "usbhid"
    "xhci_pci"
  ];
  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;
  boot.kernelModules = [
    "coretemp"
    "cpufreq_stats"
    "fuse"
    "kvm-intel"
  ];
  boot.blacklistedKernelModules = [
    "af_802154"
    "appletalk"
    "ax25"
    "btusb"
    "dccp"
    "decnet"
    "econet"
    "ipx"
    "llc"
    "n-hdlc"
    "netrom"
    "p8022"
    "p8023"
    "psnap"
    "rds"
    "rose"
    "sctp"
    "tipc"
    "uvcvideo"
    "x25"
  ];
  boot.kernelParams = [
    # General Hardening
    "debugfs=off"
    "lockdown=confidentiality"
    "module.sig_enforce=1"
    "nohibernate"
    "oops=panic"
    "vsyscall=none"

    # CPU Security Mitigations
    "intel_iommu=on"
    "iommu=pt"
    "spec_store_bypass_disable=on"

    # Memory Security
    "init_on_alloc=1"
    "page_alloc.shuffle=1"
    "slab_nomerge"
  ];

  # 3. Kernel Sysctl Settings (Hardening & Performance)
  boot.kernel.sysctl = {
    # File System Security & Performance
    "fs.file-max" = 2097152;
    "fs.inotify.max_user_instances" = 256;
    "fs.inotify.max_user_watches" = 524288;
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    "fs.suid_dumpable" = 0;

    # Kernel Hardening
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.unprivileged_bpf_disabled" = 1;
    "kernel.yama.ptrace_scope" = 1;

    # Memory Security
    "vm.mmap_rnd_bits" = 32;
    "vm.mmap_rnd_compat_bits" = 16;

    # Network Hardening
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.tcp_syncookies" = 1;

    # Network Performance
    "net.core.default_qdisc" = "fq";
    "net.core.netdev_max_backlog" = 5000;
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_max_syn_backlog" = 8192;

    # System Performance
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 15;
    "vm.swappiness" = 1;
    "vm.vfs_cache_pressure" = 50;
  };
  
  boot.zfs.devNodes = "/dev/disk/by-id";

  # 4. Hardware Configuration
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

  # 5. Power Management
  powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";

  # 6. Core System Services
  services.fwupd.enable = true;
  services.smartd = {
    enable = true;
    defaults.autodetected = "-a -o on -s (S/../.././02|L/../../7/04)";
    devices = [
      { device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX0K543315"; }
      { device = "/dev/disk/by-id/ata-Patriot_P210_1024GB_P210EDCB23011109345"; }
    ];
  };
  services.zfs = {
    arcMax = 10589934592; # 10 GB
    autoScrub.enable = true;
    autoScrub.interval = "monthly";
    autoScrub.pools = [
      "rpool"
      "dpool"
    ];
    autoSnapshot = {
      enable = true;
      flags = "-k -p --utc";
      frequent = 8;
      hourly = 24;
      daily = 7;
      weekly = 4;
      monthly = 12;
    };
    trim.enable = true;
    trim.interval = "weekly";
  };

  # 7. Custom Systemd Services
  powerManagement.powertop.enable = true;
  services.lm_sensors.enable = true;

  # 8. Filesystems
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
        "nodev"
        "nosuid"
        "noexec"
        "relatime"
      ];
    };
    "/" = {
      device = "rpool/root";
      fsType = "zfs";
    };
    "/home" = {
      device = "rpool/home";
      fsType = "zfs";
    };
    "/nix" = {
      device = "rpool/nix";
      fsType = "zfs";
    };
    "/var/log" = {
      device = "rpool/var/log";
      fsType = "zfs";
    };
    "/var/lib/postgresql" = {
      device = "rpool/var/lib/postgresql";
      fsType = "zfs";
      options = [ "zfsutil-recsize=16K" ];
    };
    "/var/lib/containers" = {
      device = "rpool/var/lib/containers";
      fsType = "zfs";
    };
    "/var/lib/redis-authentik" = {
      device = "rpool/var/lib/redis-authentik";
      fsType = "zfs";
    };
    "/var/lib/redis-paperless" = {
      device = "rpool/var/lib/redis-paperless";
      fsType = "zfs";
    };
    "/var/lib/redis-redis" = {
      device = "rpool/var/lib/redis-redis";
      fsType = "zfs";
    };
    "/var/lib/postgres-backup" = {
      device = "rpool/var/lib/postgres-backup";
      fsType = "zfs";
    };
    "/var/lib/paperless" = {
      device = "rpool/var/lib/paperless";
      fsType = "zfs";
    };
    "/var/lib/home-assistant" = {
      device = "rpool/var/lib/home-assistant";
      fsType = "zfs";
    };
    "/var/lib/microbin" = {
      device = "rpool/var/lib/microbin";
      fsType = "zfs";
    };
    "/var/lib/ldap" = {
      device = "rpool/var/lib/ldap";
      fsType = "zfs";
    };
    "/var/lib/authentik" = {
      device = "rpool/var/lib/authentik";
      fsType = "zfs";
    };
    "/var/lib/vaultwarden" = {
      device = "rpool/var/lib/vaultwarden";
      fsType = "zfs";
    };
    "/var/lib/grafana" = {
      device = "rpool/var/lib/grafana";
      fsType = "zfs";
    };
    "/var/lib/prometheus2" = {
      device = "rpool/var/lib/prometheus2";
      fsType = "zfs";
    };
    "/var/lib/acme" = {
      device = "rpool/var/lib/acme";
      fsType = "zfs";
    };
    "/var/lib/nginx" = {
      device = "rpool/var/lib/nginx";
      fsType = "zfs";
    };
    "/data/media/.state" = {
      device = "rpool/data/media/.state";
      fsType = "zfs";
    };
    "/data" = {
      device = "dpool/data";
      fsType = "zfs";
    };
  };

  # 9. Swap
  swapDevices = [ { device = "/dev/zvol/rpool/zfs_swap"; } ];
}
