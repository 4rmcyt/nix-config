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

    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;

    supportedFilesystems = [ "zfs" ];
    kernelParams = [
      "zfs.zfs_arc_max=12884901888"
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
    };
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
}
