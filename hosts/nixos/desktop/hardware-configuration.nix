{
  config,
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}: {
  # =================================================================
  # 1. Imports
  # =================================================================
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  # Apply cachyos-kernel pinned overlay (localized to this host)
  nixpkgs.overlays = [inputs.cachyos-kernel.overlays.pinned];

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
      "snd_hda_codec_hdmi"
      "snd_hda_codec_realtek"
      "snd_hda_intel"
      "v4l2loopback"
    ];

    extraModulePackages = with config.boot.kernelPackages; [
      v4l2loopback
      zenpower
    ];

    # Module configuration
    extraModprobeConfig = ''
      # Enable v4l2loopback for virtual camera
      options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
    '';

    # TODO: Switch back to linuxPackages-cachyos-latest-lto-zen4 when patches are fixed
    # Use cachyos kernel directly from input for binary cache support
    kernelPackages = inputs.cachyos-kernel.packages.${pkgs.system}.linuxPackages-cachyos-lts-lto;
    supportedFilesystems = ["zfs"];

    # Kernel parameters
    kernelParams = [
      # AMD CPU optimizations (Zen 4)
      "amd_pstate=active" # Use CPPC EPP driver for best Zen 4 performance
      "amd_prefcore=1" # Prefer highest boost frequency cores
      "microcode.amd_sha_check=off"

      # AMD GPU optimizations (integrated Radeon Graphics)
      "amdgpu.dpm=1" # Enable dynamic power management
      "amdgpu.ppfeaturemask=0xfffd7fff" # Enable all PowerPlay features

      # Security mitigations (Zen 4 benefits from keeping these enabled)
      "mitigations=auto"

      # Network optimizations
      "net.core.default_qdisc=fq"
      "net.ipv4.tcp_congestion_control=bbr"

      # NVIDIA GPU
      "nvidia-drm.fbdev=1"
      "nvidia-drm.modeset=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"

      # Scheduler and preemption
      "preempt=full" # Full preemption for desktop responsiveness

      # ZFS
      "zfs.zfs_arc_max=25769803776" # 24GB ARC (40% of 62GB RAM)

      # System configuration
      "cfg80211.ieee80211_regdom=CA"
      "loglevel=4"
      "nohibernate"
      "rd.systemd.show_status=auto"
      "rd.udev.log_priority=3"
      "systemd.unified_cgroup_hierarchy=1"
      "usb-storage.delay_use=0"
      "usbcore.autosuspend=-1"
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
      "kernel.nmi_watchdog" = 0; # Disable NMI watchdog to reduce interrupts and save power

      # VM/Memory optimizations for 62GB RAM system
      "vm.swappiness" = 10; # Reduce swap usage with abundant RAM
      "vm.vfs_cache_pressure" = 50; # Keep more inodes/dentries cached
      "vm.dirty_ratio" = 10; # Start writing dirty pages at 10% RAM
      "vm.dirty_background_ratio" = 5; # Background writes at 5% RAM

      # ZFS-specific optimizations for Zen 4
      "vm.min_free_kbytes" = 1048576; # 1GB min free for ZFS ARC stability

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
      "net.ipv4.tcp_fastopen" = 3;
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
          Experimental = true;
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
    memoryPercent = 15; # 15% of 62GB = ~9GB compressed swap (reduced from 30%)
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
