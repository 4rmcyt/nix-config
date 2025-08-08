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

  fileSystems = {
    "/" = {
      device = "system/root";
      fsType = "zfs";
    };

    "/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };


    "/nix" = {
      device = "system/root/nix";
      fsType = "zfs";
    };

    "/home" = {
      device = "system/root/home";
      fsType = "zfs";
    };

    "/var" = {
      device = "system/root/var";
      fsType = "zfs";
    };

    "/var/log" = {
      device = "system/root/var/log";
      fsType = "zfs";
    };

    # Mounts for your various services in /var/lib
    "/var/lib/postgresql" = { device = "system/root/var/lib/postgresql"; fsType = "zfs"; };
    "/var/lib/containers" = { device = "system/root/var/lib/containers"; fsType = "zfs"; };
    "/var/lib/redis-authentik" = { device = "system/root/var/lib/redis-authentik"; fsType = "zfs"; };
    "/var/lib/redis-paperless" = { device = "system/root/var/lib/redis-paperless"; fsType = "zfs"; };
    "/var/lib/redis-redis" = { device = "system/root/var/lib/redis-redis"; fsType = "zfs"; };
    "/var/lib/postgres-backup" = { device = "system/root/var/lib/postgres-backup"; fsType = "zfs"; };
    "/var/lib/paperless" = { device = "system/root/var/lib/paperless"; fsType = "zfs"; };
    "/var/lib/home-assistant" = { device = "system/root/var/lib/home-assistant"; fsType = "zfs"; };
    "/var/lib/microbin" = { device = "system/root/var/lib/microbin"; fsType = "zfs"; };
    "/var/lib/ldap" = { device = "system/root/var/lib/ldap"; fsType = "zfs"; };
    "/var/lib/authentik" = { device = "system/root/var/lib/authentik"; fsType = "zfs"; };
    "/var/lib/vaultwarden" = { device = "system/root/var/lib/vaultwarden"; fsType = "zfs"; };
    "/var/lib/grafana" = { device = "system/root/var/lib/grafana"; fsType = "zfs"; };
    "/var/lib/prometheus2" = { device = "system/root/var/lib/prometheus2"; fsType = "zfs"; };
    "/var/lib/acme" = { device = "system/root/var/lib/acme"; fsType = "zfs"; };
    "/var/lib/nginx" = { device = "system/root/var/lib/nginx"; fsType = "zfs"; };

    # Mounts for your data pool
    "/data" = {
      device = "data/data";
      fsType = "zfs";
    };

    "/data/media" = { device = "data/data/media"; fsType = "zfs"; };
    "/data/media/movies" = { device = "data/data/media/movies"; fsType = "zfs"; };
    "/data/media/shows" = { device = "data/data/media/shows"; fsType = "zfs"; };
    "/data/media/music" = { device = "data/data/media/music"; fsType = "zfs"; };
    "/data/media/audiobooks" = { device = "data/data/media/audiobooks"; fsType = "zfs"; };
    "/data/media/books" = { device = "data/data/media/books"; fsType = "zfs"; };
    "/data/media/comics" = { device = "data/data/media/comics"; fsType = "zfs"; };
    "/data/media/manga" = { device = "data/data/media/manga"; fsType = "zfs"; };
    "/data/media/torrents" = { device = "data/data/media/torrents"; fsType = "zfs"; };
    "/data/media/usenet" = { device = "data/data/media/usenet"; fsType = "zfs"; };
    "/data/media/.state" = { device = "data/data/media/.state"; fsType = "zfs"; };
    "/data/Downloads" = { device = "data/data/Downloads"; fsType = "zfs"; };
  };

  # 3. Enable the swap device
  swapDevices = [
    { device = "/dev/zvol/system/root/swap"; }
  ];
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

    "kernel.watchdog_thresh" = 60; # Set watchdog threshold to 60 seconds
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
      "system" # FIX: Was "rpool"
      "data"   # FIX: Was "dpool"
    ];
    autoSnapshot.enable = false;
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
