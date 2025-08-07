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
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.systemd-boot.editor = false;
  boot.loader.timeout = 3;

  # Define filesystem support and ZFS settings for the initial ramdisk (initrd).
  boot.supportedFilesystems = [ "zfs" ];

  # Define kernel modules needed early in the boot process.
  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "usb_storage"
    "usbhid"
    "xhci_pci"
  ];

  # Mount points for all filesystems.
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

    # Root and core ZFS datasets
    "/" = {
      device = "rpool/root";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
    "/home" = {
      device = "rpool/home";
      fsType = "zfs";
      options = [ "zfsutil-compression=on" ];
    }; # atime can be useful on /home
    "/nix" = {
      device = "rpool/nix";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };

    # Log and service data datasets with performance optimizations
    "/var/log" = {
      device = "rpool/var/log";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
    "/var/lib/acme" = {
      device = "rpool/var/lib/acme";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
    "/var/lib/authentik" = {
      device = "rpool/var/lib/authentik";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
    "/var/lib/containers" = {
      device = "rpool/var/lib/containers";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
    "/var/lib/grafana" = {
      device = "rpool/var/lib/grafana";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
    "/var/lib/home-assistant" = {
      device = "rpool/var/lib/home-assistant";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
    "/var/lib/ldap" = {
      device = "rpool/var/lib/ldap";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
    "/var/lib/microbin" = {
      device = "rpool/var/lib/microbin";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
    "/var/lib/nginx" = {
      device = "rpool/var/lib/nginx";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
    "/var/lib/paperless" = {
      device = "rpool/var/lib/paperless";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
    "/var/lib/postgres-backup" = {
      device = "rpool/var/lib/postgres-backup";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
    "/var/lib/postgresql" = {
      device = "rpool/var/lib/postgresql";
      fsType = "zfs";
      options = [
        "zfsutil-recsize=16K"
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
    "/var/lib/prometheus2" = {
      device = "rpool/var/lib/prometheus2";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
    "/var/lib/redis-authentik" = {
      device = "rpool/var/lib/redis-authentik";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
    "/var/lib/redis-paperless" = {
      device = "rpool/var/lib/redis-paperless";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
    "/var/lib/redis-redis" = {
      device = "rpool/var/lib/redis-redis";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
    "/var/lib/vaultwarden" = {
      device = "rpool/var/lib/vaultwarden";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
    "/var/lib/loki" = {
      device = "rpool/var/lib/loki";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };

    # Secondary data pool
    "/data" = {
      device = "dpool/data";
      fsType = "zfs";
      options = [ "zfsutil-compression=on" ];
    };
    "/data/media/.state" = {
      device = "rpool/data/media/.state";
      fsType = "zfs";
      options = [
        "zfsutil-atime=off"
        "zfsutil-compression=on"
      ];
    };
  };

  # Swap on a ZFS ZVOL.
  swapDevices = [ { device = "/dev/zvol/rpool/zfs_swap"; } ];

  # =================================================================
  # 3. Kernel Configuration
  # =================================================================
  # Use the Zen kernel for desktop-oriented performance tuning.
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;

  # Kernel modules to load at boot.
  boot.kernelModules = [
    "coretemp"
    "cpufreq_stats"
    "fuse"
    "kvm-intel"
    "iTCO_wdt"
  ];

  # Unused modules to prevent from loading, reducing attack surface.
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

  # Kernel parameters for security and performance.
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

    # AppArmor Security
    "apparmor=1"

    # ZFS Performance Tuning
    "zfs.zfs_arc_max=12884901888" 
  ];

  # Sysctl settings for hardening and performance tuning.
  boot.kernel.sysctl = {
    # FS Security & Performance
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

    "kernel.watchdog_thresh" = 60; # Set watchdog threshold to 10 seconds
  };

  # =================================================================
  # 4. Hardware & Power Management
  # =================================================================
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

  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  powerManagement.powertop.enable = true;

  # =================================================================
  # 5. System Services
  # =================================================================
  services.fwupd.enable = true;
  systemd.oomd.enable = true;


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
    autoScrub.pools = [
      "rpool"
      "dpool"
    ];
    autoSnapshot.enable = true;
    autoSnapshot.flags = "-k -p --utc";
    autoSnapshot.frequent = 8;
    autoSnapshot.hourly = 24;
    autoSnapshot.daily = 7;
    autoSnapshot.weekly = 4;
    autoSnapshot.monthly = 12;
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
    avahi.enable = false; # mDNS discovery
    printing.enable = false; # CUPS printing
  };
  systemd.coredump.enable = false;
}
