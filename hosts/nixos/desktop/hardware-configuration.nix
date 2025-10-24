{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  xanmodCompatibleKernelPackages =
    lib.filterAttrs (
      name: kernelPackages:
        (builtins.match "linuxPackages_xanmod.*" name)
        != null
        && (builtins.tryEval kernelPackages).success
        && kernelPackages ? ${config.boot.zfs.package.kernelModuleAttribute}
        && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken or false)
    )
    pkgs;

  selectedKernelPackage = let
    xanmodPackages = builtins.attrValues xanmodCompatibleKernelPackages;
  in
    if (builtins.length xanmodPackages) > 0
    then
      lib.last (
        lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) xanmodPackages
      )
    else pkgs.linuxPackages_xanmod_latest;
in {
  # =================================================================
  # 1. Imports
  # =================================================================
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  # =================================================================
  # 2. Boot Configuration
  # =================================================================
  boot = {
    # Kernel modules
    initrd.availableKernelModules = [
      "ahci"
      "amdgpu"
      "btusb"
      "mt7921e"
      "nvme"
      "r8169"
      "sd_mod"
      "usb_storage"
      "usbhid"
      "xhci_pci"
    ];

    initrd.kernelModules = [
      "pci-stub"
    ];

    kernelModules = [
      "amdgpu"
      "bluetooth"
      "btusb"
      "k10temp"
      "kvm-amd"
      "mt7921e"
      "nvidia"
      "nvidia_drm"
      "nvidia_modeset"
      "nvidia_uvm"
      "pci-stub"
      "r8169"
      "snd-usb-audio"
      "snd_hda_intel"
      "snd_hda_codec_hdmi"
      "snd_hda_codec_realtek"
      "v4l2loopback"
    ];

    # Kernel configuration
    kernelPackages = selectedKernelPackage;
    supportedFilesystems = ["zfs"];

    # Kernel parameters
    kernelParams = [
      "net.core.default_qdisc=fq"
      "net.ipv4.tcp_congestion_control=bbr"
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "zfs.zfs_arc_max=12884901888" # 12GB ARC size
      "cfg80211.ieee80211_regdom=CA"
      "nohibernate"
      "loglevel=4"
      "usbcore.autosuspend=-1"
      "usb-storage.delay_use=0"
    ];

    # ZFS configuration
    zfs = {
      forceImportRoot = true;
      forceImportAll = true;
    };

    # System control parameters
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

    # Pre-boot commands
    initrd.preLVMCommands = ''
      ${pkgs.kbd}/bin/setleds +num
    '';

    extraModulePackages = with config.boot.kernelPackages; [
      v4l2loopback
      zenpower
    ];
    # Module configuration
    extraModprobeConfig = ''
      options zfs l2arc_noprefetch=0 l2arc_write_boost=33554432 l2arc_write_max=16777216 zfs_arc_max=2147483648

      # Enable v4l2loopback for virtual camera
      options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
    '';
  };

  # =================================================================
  # 3. Hardware Configuration
  # =================================================================
  hardware = {
    # Graphics
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    # NVIDIA configuration
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = false;
        };
      };
    };

    # CPU configuration
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    enableRedistributableFirmware = lib.mkDefault true;
    cpu.amd.ryzen-smu.enable = true;

    gpgSmartcards.enable = true;
  };

  # =================================================================
  # 4. Services
  # =================================================================
  services = {
    # Hardware monitoring
    smartd = {
      enable = true;
      defaults.autodetected = "-a -o on -s (S/../.././02|L/../../7/04)";
      devices = [
        {device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_1TB_S6S1NS0W101791N";}
      ];
    };

    # OpenRGB for RGB control
    hardware.openrgb.enable = true;

    # ZFS services
    zfs = {
      autoScrub = {
        enable = true;
        interval = "weekly";
      };
      trim = {
        enable = true;
        interval = "weekly";
      };
    };

    journald = {
      extraConfig = ''
        SystemMaxUse=1G
        SystemMaxFileSize=100M
        MaxRetentionSec=1month
        ForwardToSyslog=no
        Storage=persistent
      '';
    };
  };

  # =================================================================
  # 5. Swap Configuration
  # =================================================================
  swapDevices = [];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 30;
  };

  security = {
    rtkit.enable = true;
    polkit.enable = true;
  };
  # =================================================================
  # 7. Networking
  # =================================================================
  networking.useDHCP = lib.mkDefault true;

  # =================================================================
  # 8. Platform Configuration
  # =================================================================
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  systemd = {
    coredump.enable = false;
    oomd.enable = true;
  };
}
