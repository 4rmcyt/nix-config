{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

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
  boot.kernelParams = [ "nohibernate" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.systemd-boot.editor = false;
  boot.loader.timeout = 3;

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

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

  services.zfs.autoScrub.enable = true;

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
