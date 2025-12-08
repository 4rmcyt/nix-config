{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
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
      "snd_hda_codec_generic"
      "snd_hda_codec_hdmi"
      "snd_hda_intel"
      "v4l2loopback"
    ];

    extraModulePackages = with config.boot.kernelPackages; [
      zenpower
    ];

    # Module configuration
    extraModprobeConfig = ''
      # Enable v4l2loopback for virtual camera
      options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1

      # USB audio optimizations
      options snd-usb-audio implicit_fb=1 use_vmalloc=1 quirk_flags=0x80

      # HDA audio optimizations
      options snd-hda-intel power_save=0 power_save_controller=N probe_mask=1
    '';

    # Kernel configuration - CachyOS with LTO and Zen4 optimizations
    kernelPackages = pkgs.linuxPackages_cachyos-lto-znver4;
    zfs.package = pkgs.zfs_cachyos;
    supportedFilesystems = ["zfs"];

    # Kernel parameters
    kernelParams = [
      "amd_pstate=active" # Use CPPC-based driver for faster response
      "amd_prefcore=1" # Prefer V-Cache CCD for latency-sensitive threads
      "cfg80211.ieee80211_regdom=CA"
      "loglevel=4"
      "microcode.amd_sha_check=off"
      "mitigations=off"
      "net.core.default_qdisc=fq"
      "net.ipv4.tcp_congestion_control=bbr"
      "nohibernate"
      "nvidia-drm.fbdev=1"
      "nvidia-drm.modeset=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "preempt=full"
      "pti=off"
      "rd.systemd.show_status=auto"
      "rd.udev.log_priority=3"
      "retbleed=off" # big performance impact
      "spectre_v2=off"
      "systemd.unified_cgroup_hierarchy=1"
      "usb-storage.delay_use=0"
      "usbcore.autosuspend=-1"
      "zfs.zfs_arc_max=12884901888" # 12GB ARC size
    ];

    # ZFS configuration
    zfs = {
      forceImportRoot = true;
      forceImportAll = true;
    };

    # System control parameters
    kernel.sysctl = {
      # Kernel optimizations
      "kernel.split_lock_mitigate" = 0;

      # Network queue and backlog
      "net.core.busy_poll" = 50;
      "net.core.busy_read" = 50;
      "net.core.netdev_budget" = 600;
      "net.core.netdev_max_backlog" = 5000;

      # TCP Buffer sizes
      "net.core.rmem_default" = 262144;
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_default" = 262144;
      "net.core.wmem_max" = 16777216;

      # Increase local port range
      "net.ipv4.ip_local_port_range" = "1024 65535";

      # TCP optimizations
      "net.ipv4.tcp_fack" = 1;
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_low_latency" = 1;
      "net.ipv4.tcp_no_delay" = 1;
      "net.ipv4.tcp_rmem" = "4096 65536 16777216";
      "net.ipv4.tcp_sack" = 1;
      "net.ipv4.tcp_timestamps" = 1;
      "net.ipv4.tcp_tw_reuse" = 1;
      "net.ipv4.tcp_window_scaling" = 1;
      "net.ipv4.tcp_wmem" = "4096 65536 16777216";
    };

    # Pre-boot commands
    initrd.preLVMCommands = ''
      ${pkgs.kbd}/bin/setleds +num
    '';

    # Tmp configuration
    tmp.useTmpfs = true;
    tmp.tmpfsSize = "100%";
    tmp.tmpfsHugeMemoryPages = "within_size";
  };

  # =================================================================
  # 3. Hardware Configuration
  # =================================================================
  hardware = {
    # AMD GPU
    amdgpu.overdrive.enable = true;

    # Bluetooth
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

    # CPU
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # Firmware
    enableRedistributableFirmware = lib.mkDefault true;

    # GPG Smartcards
    gpgSmartcards.enable = true;

    # Graphics
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        rocmPackages.clr
        rocmPackages.clr.icd
      ];
    };

    # NVIDIA configuration
    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
      powerManagement.enable = false;
    };
  };

  # =================================================================
  # 4. Security
  # =================================================================
  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  # =================================================================
  # 5. Services
  # =================================================================
  services = {
    # OpenRGB for RGB control
    hardware.openrgb.enable = true;

    # Journald
    journald = {
      extraConfig = ''
        SystemMaxUse=1G
        SystemMaxFileSize=100M
        MaxRetentionSec=1month
        ForwardToSyslog=no
        Storage=persistent
      '';
    };

    # SCX Scheduler
    scx = {
      enable = true;
      package = pkgs.scx.full;
      scheduler = "scx_bpfland";
      extraArgs = [
        "-m"
        "performance"
      ];
    };

    # Hardware monitoring
    smartd = {
      autodetect = true;
      defaults.autodetected = "-a -o on -s (S/../.././02|L/../../7/04)";
      enable = true;
    };

    # Microcode updates
    ucodenix = {
      enable = true;
      cpuModelId = ./facter.json;
    };

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
  };

  # =================================================================
  # 6. Networking
  # =================================================================
  networking.useDHCP = lib.mkDefault true;

  # =================================================================
  # 7. Swap Configuration
  # =================================================================
  swapDevices = [];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 30;
  };

  # =================================================================
  # 8. Systemd Configuration
  # =================================================================
  systemd = {
    coredump.enable = false;
    oomd.enable = true;
  };

  # =================================================================
  # 9. Platform Configuration
  # =================================================================
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
