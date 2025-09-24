{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
      "amdgpu"
      "r8169"
      "mt7921e"
      "btusb"
    ];

    initrd.kernelModules = [ ];

    kernelModules = [
      "kvm-amd"
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
      "amdgpu"
      "r8169"
      "mt7921e"
      "k10temp"
      "snd_hda_intel"
      "snd-usb-audio"
      "btusb"
    ];

    kernelPackages = pkgs.linuxPackages_xanmod_latest;

    supportedFilesystems = [ "zfs" ];
    kernelParams = [
      "zfs.zfs_arc_max=12884901888"
      "zfs.zfs_txg_timeout=30"
      "nvidia-drm.modeset=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "usbcore.quirks=0bda:0411:b"
      "net.core.default_qdisc=fq"
      "net.ipv4.tcp_congestion_control=bbr"
    ];
    zfs = {
      forceImportRoot = true;
      forceImportAll = true;
    };
    kernel.sysctl = {
      # TCP Buffer sizes
      "net.core.rmem_default" = 262144;
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_default" = 262144;
      "net.core.wmem_max" = 16777216;
      "net.ipv4.tcp_rmem" = "4096 65536 16777216";
      "net.ipv4.tcp_wmem" = "4096 65536 16777216";

      # Network queue and backlog
      "net.core.netdev_max_backlog" = 5000;
      "net.core.netdev_budget" = 600;

      # TCP optimizations
      "net.ipv4.tcp_window_scaling" = 1;
      "net.ipv4.tcp_timestamps" = 1;
      "net.ipv4.tcp_sack" = 1;
      "net.ipv4.tcp_fack" = 1;
      "net.ipv4.tcp_low_latency" = 1;
      "net.ipv4.tcp_fastopen" = 3;

      # Reduce TIME_WAIT sockets
      "net.ipv4.tcp_tw_reuse" = 1;

      # Increase local port range
      "net.ipv4.ip_local_port_range" = "1024 65535";

      # Gaming optimizations
      "net.ipv4.tcp_no_delay" = 1;
      "net.core.busy_read" = 50;
      "net.core.busy_poll" = 50;

      "vm.dirty_background_ratio" = 2;
      "vm.dirty_ratio" = 5;
      "vm.dirty_expire_centisecs" = 1500;
      "vm.dirty_writeback_centisecs" = 6000;
      "vm.swappiness" = 1;
    };
    initrd.preLVMCommands = ''
      ${pkgs.kbd}/bin/setleds +num
    '';
  };

  services.smartd = {
    enable = true;
    defaults.autodetected = "-a -o on -s (S/../.././02|L/../../7/04)";
    devices = [
      { device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_S6S1NS0W101791N"; }
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
      open = false;
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
    trim = {
      enable = true;
      interval = "weekly";
    };
  };

  # NVIDIA environment variables
  environment.variables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = lib.mkDefault true;
  hardware.cpu.amd.ryzen-smu.enable = true;

  # Firefox cache in tmpfs (2GB should be plenty)
  fileSystems."/home/zeev/.cache/mozilla" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=2G" # 2GB for Firefox cache
      "mode=0755"
      "uid=1000"
      "gid=100"
      "noatime" # No access time updates
      "nodev" # Security: no device files
      "nosuid" # Security: no suid binaries
    ];
  };

  # Optional: More aggressive tmpfs for all browser caches
  fileSystems."/home/zeev/.cache/chromium" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=1G"
      "mode=0755"
      "uid=1000"
      "gid=100"
      "noatime"
    ];
  };

  # VS Code cache (those libuv workers writing heavily)
  fileSystems."/home/zeev/.cache/vscode-cpptools" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=512M"
      "mode=0755"
      "uid=1000"
      "gid=100"
      "noatime"
    ];
  };

  # General /tmp with more space
  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=8G" # Generous /tmp space
      "mode=1777" # Sticky bit for multi-user
      "noatime"
    ];
  };
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 10; # Only 6.4GB - emergency only
  };

  systemd.user.tmpfiles.rules = [
    "d %h/.cache/mozilla 0755 zeev users 7d"
  ];
}
