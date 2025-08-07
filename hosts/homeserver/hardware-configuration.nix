{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  #   boot = {
  #   loader = {
  #     systemd-boot = {
  #       enable = true;
  #       # Security: disable editing boot entries
  #       editor = false;
  #       configurationLimit = 10;  # Limit old generations
  #     };
  #     efi.canTouchEfiVariables = true;

  #     # Secure boot timeout
  #     timeout = 3;
  #   };

  #   # Kernel hardening
  #   kernelParams = [
  #     "slab_nomerge"
  #     "init_on_alloc=1"
  #     "init_on_free=1"
  #     "page_alloc.shuffle=1"
  #     "pti=on"
  #     "vsyscall=none"
  #     "debugfs=off"
  #     "oops=panic"
  #     "module.sig_enforce=1"
  #     "lockdown=confidentiality"
  #   ];

  #   # Disable unnecessary kernel modules
  #   blacklistedKernelModules = [
  #     "dccp"
  #     "sctp"
  #     "rds"
  #     "tipc"
  #     "n-hdlc"
  #     "ax25"
  #     "netrom"
  #     "x25"
  #     "rose"
  #     "decnet"
  #     "econet"
  #     "af_802154"
  #     "ipx"
  #     "appletalk"
  #     "psnap"
  #     "p8023"
  #     "llc"
  #     "p8022"
  #   ];
  # };

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "ahci"
    "usb_storage"
    "usbhid"
  ];

  boot.supportedFilesystems = [ "zfs" ];
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;
  boot.kernelModules = [
    "kvm-intel"
    "cpufreq_stats"
    "coretemp"
    "fuse"
  ];
  boot.kernelParams = [
    "nohibernate"
    "zfs.zfs_arc_max=8589934592"
    "intel_iommu=on" # Enable IOMMU
    "iommu=pt" # Passthrough mode
    "spectre_v2=on" # Spectre v2 mitigation
    "spec_store_bypass_disable=on" # Speculative store bypass
    "tsx=off" # Disable TSX
    "tsx_async_abort=full,nosmt" # TSX async abort mitigation
    # Memory protection
    "slab_nomerge"
    "init_on_alloc=1"
    "init_on_free=1"
    "page_alloc.shuffle=1"

    # CPU security
    "pti=on"
    "spectre_v2=on"
    "spec_store_bypass_disable=on"

    # Kernel hardening
    "vsyscall=none"
    "debugfs=off"
    "oops=panic"
    "module.sig_enforce=1"
    "lockdown=confidentiality"

    # Disable legacy features
    "nohibernate"
    "nosmt" # Disable SMT if not needed for security
  ];
  # Blacklist vulnerable modules
  blacklistedKernelModules = [
    "dccp"
    "sctp"
    "rds"
    "tipc"
    "n-hdlc"
    "ax25"
    "netrom"
    "x25"
    "rose"
    "decnet"
    "econet"
    "af_802154"
    "ipx"
    "appletalk"
    "psnap"
    "p8023"
    "llc"
    "p8022"
    "bluetooth"
    "btusb" # If not using Bluetooth
    "uvcvideo" # If no webcam
  ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl = {

    # Memory security
    "vm.mmap_rnd_bits" = 32;
    "vm.mmap_rnd_compat_bits" = 16;

    # Performance: file system
    "fs.file-max" = 2097152;
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 256;

    # Security: kernel hardening
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.yama.ptrace_scope" = 1;
    "kernel.unprivileged_bpf_disabled" = 1;
    "kernel.unprivileged_userns_clone" = 0;

    # Security: network hardening
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_rfc1337" = 1;

    # Performance: server optimizations
    "vm.swappiness" = 1;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_ratio" = 15;
    "vm.dirty_background_ratio" = 5;

    # File system security
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    "fs.suid_dumpable" = 0;

    # Network performance
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.netdev_max_backlog" = 5000;
    "net.ipv4.tcp_max_syn_backlog" = 8192;
  };
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.systemd-boot.editor = false;
  boot.loader.timeout = 3;

  enableRedistributableFirmware = true;

  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-vaapi-driver
    vaapiIntel
    vaapiVdpau
    intel-compute-runtime
    intel-ocl
    libvdpau-va-gl
  ];

  hardware.bluetooth.enable = false;
  hardware.pulseaudio.enable = false;

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  services.fwupd.enable = true;
  services.smartd = {
    enable = true;
    defaults.autodetected = "-a -o on -s (S/../.././02|L/../../7/04)";
    devices = [
      { device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX0K543315"; }
      { device = "/dev/disk/by-id/ata-Patriot_P210_1024GB_P210EDCB23011109345"; }
    ];
  };

  systemd.services.power-tune = {
    description = "Power Management tunings";
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.powertop}/bin/powertop --auto-tune
    '';
    serviceConfig.Type = "oneshot";
  };
  systemd.services.lm_sensors = {
    description = "LM Sensors Service";
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.lm_sensors}/bin/sensors-detect --auto
    '';
    serviceConfig.Type = "oneshot";
  };

  systemd.services.temperature-monitor = {
    description = "Monitor system temperatures";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "temp-monitor" ''
        # Check CPU temperature
        CPU_TEMP=$(${pkgs.lm_sensors}/bin/sensors | grep "Core 0" | awk '{print $3}' | sed 's/+//;s/°C//' | cut -d'.' -f1)
        if [ "$CPU_TEMP" -gt 80 ]; then
          echo "WARNING: CPU temperature is $CPU_TEMP°C" | ${pkgs.systemd}/bin/systemd-cat -t temp-monitor -p warning
        fi
      '';
    };
  };

  systemd.timers.temperature-monitor = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/5"; # Every 5 minutes
      Persistent = true;
    };
  };

  services.zfs.autoScrub.enable = true;

  #   services.zfs = {
  #   autoScrub = {
  #     enable = true;
  #     interval = "monthly";  # Make interval explicit
  #     pools = [ "rpool" "dpool" ];  # Specify pools explicitly
  #   };

  #   # Add ZFS auto-snapshot
  #   autoSnapshot = {
  #     enable = true;
  #     flags = "-k -p --utc";
  #     frequent = 8;     # Keep 8 15-minute snapshots
  #     hourly = 24;      # Keep 24 hourly snapshots
  #     daily = 7;        # Keep 7 daily snapshots
  #     weekly = 4;       # Keep 4 weekly snapshots
  #     monthly = 12;     # Keep 12 monthly snapshots
  #   };

  #   # Add ZFS trim for SSDs
  #   trim = {
  #     enable = true;
  #     interval = "weekly";
  #   };
  # };

  fileSystems = {
    # The boot partition, which is a standard vfat filesystem.
    "/boot" = {
      device = "/dev/disk/by-label/boot"; # Disko automatically labels the boot partition.
      fsType = "vfat";
      options = [
        "fmask=0137"
        "dmask=0027"
      ];
    };

    #   "/boot" = {
    #   device = "/dev/disk/by-label/boot";
    #   fsType = "vfat";
    #   options = [
    #     "fmask=0077"    # Changed from 0137 - more restrictive
    #     "dmask=0077"    # Changed from 0027 - more restrictive
    #     "nodev"         # No device files
    #     "nosuid"        # No setuid binaries
    #     "noexec"        # No executable files (except kernel/initrd)
    #   ];
    # };

    # ZFS datasets from the 'rpool' (root pool).
    # NixOS's ZFS integration automatically mounts datasets, but explicitly listing
    # them here provides clarity and ensures the system knows about them.
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

    # ZFS dataset from the 'dpool' (data pool).
    "/data" = {
      device = "dpool/data";
      fsType = "zfs";
    };
  };

  # Swap device configuration.
  # Disko creates a ZFS volume (zvol) for swap on the root pool.
  swapDevices = [
    {
      # The device path is derived from the pool name ('rpool') and the
      # name you gave the swap device in the disko config ('zfs_swap').
      device = "/dev/zvol/rpool/zfs_swap";
    }
  ];
}
