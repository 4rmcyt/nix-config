{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  zfsCompatibleKernelPackages =
    lib.filterAttrs (
      name: kernelPackages:
        (builtins.match "linux_(xanmod_latest|[0-9]+_[0-9]+)" name)
        != null
        && (builtins.tryEval kernelPackages).success
        && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
    )
    pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: lib.versionOlder a.kernel.version b.kernel.version) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
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
      "snd_hda_codec_hdmi"
      "snd_hda_codec_realtek"
      "snd_hda_intel"
      "v4l2loopback"
      "nct6687d"
      "zenergy"
    ];

    kernelPackages = latestKernelPackage;

    extraModulePackages = with config.boot.kernelPackages; [
      v4l2loopback
      zenergy
      ryzen-smu
      nct6687d
    ];

    # Module configuration
    extraModprobeConfig = ''
      # Enable v4l2loopback for virtual camera
      options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
    '';

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
      # MSI MYSTIC LIGHT (1462:7d75) disabled via udev authorized=0 — no kernel quirks needed

      # Display output hints for early modesetting
      "video=DP-4:1920x1080@60"
      "video=DP-5:1920x1080@60"
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
        Policy = {
          AutoEnable = true;
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
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      powerManagement.enable = true;
    };
  };

  # =================================================================
  # 4. Boot Loader
  # =================================================================
  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = false;
    limine = {
      enable = true;
      enableEditor = false;
      maxGenerations = 10;
      validateChecksums = true;
      panicOnChecksumMismatch = true;
      efiSupport = true;
      efiInstallAsRemovable = false;
      biosSupport = false;
    };
  };

  # =================================================================
  # 5. Security (hardware-tied: PAM U2F / YubiKey)
  # =================================================================
  security = {
    polkit.enable = true;
    rtkit.enable = true;
    pam.services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
    };
    pam.u2f = {
      enable = true;
      control = "optional";
      settings = {
        authfile = "/etc/u2f_mappings";
        cue = true;
      };
    };
  };

  nixpkgs.config.cudaSupport = true;

  # MT7922: commit ba41835 in linux-firmware broke mt7921e init (WM Version: ____000000).
  # Replace the two broken firmware blobs with pre-ba41835 versions from 20250808.
  # https://github.com/NixOS/nixpkgs/issues/444538
  nixpkgs.overlays = [
    (_final: prev: {
      linux-firmware = prev.linux-firmware.overrideAttrs (old: {
        postInstall =
          (old.postInstall or "")
          + ''
            cp ${prev.fetchurl {
              url = "https://gitlab.com/kernel-firmware/linux-firmware/-/raw/20250808/mediatek/WIFI_RAM_CODE_MT7922_1.bin";
              sha256 = "19jfkmpqngm0d3wpv2inc9hmmqjfk5nhbw5d6mkvh23idg3w2jm3";
            }} $out/lib/firmware/mediatek/WIFI_RAM_CODE_MT7922_1.bin
            cp ${prev.fetchurl {
              url = "https://gitlab.com/kernel-firmware/linux-firmware/-/raw/20250808/mediatek/WIFI_MT7922_patch_mcu_1_1_hdr.bin";
              sha256 = "1q4irdjmbfpx8fsv8qiprzklvm62z614vchyjnhpbh2745bxl65y";
            }} $out/lib/firmware/mediatek/WIFI_MT7922_patch_mcu_1_1_hdr.bin
          '';
      });
    })
  ];

  # =================================================================
  # 6. Hardware Programs
  # =================================================================
  programs = {
    corectrl.enable = true; # AMD GPU / CPU control
    noisetorch.enable = true; # Noise suppression (audio hardware)
  };

  # =================================================================
  # 7. Services
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

    # CPU frequency scaling
    auto-cpufreq = {
      enable = true;
      settings.charger = {
        governor = "performance";
        turbo = "auto";
      };
    };

    # Firmware updates
    fwupd = {
      enable = true;
      extraRemotes = [
        "lvfs-testing"
        "vendor"
      ];
    };

    # Smartcard / YubiKey
    pcscd = {
      enable = true;
      plugins = [pkgs.ccid];
    };

    # iOS device support
    usbmuxd.enable = true;

    # Audio
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      wireplumber.enable = true;
      jack.enable = true;
      extraConfig.pipewire."92-low-latency" = {
        context.properties = {
          default.clock.max-quantum = 32;
          default.clock.min-quantum = 32;
          default.clock.quantum = 32;
          default.clock.rate = 48000;
        };
      };
      extraConfig.pipewire."93-screen-share" = {
        "stream.properties"."node.max-latency" = "1/60";
        context.spa-libs = {
          "api.libcamera.*" = "libcamera/libspa-libcamera";
          "support.*" = "support/libspa-support";
        };
      };
      extraConfig.pipewire."99-usb-audio-fix" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 512;
          "default.clock.min-quantum" = 64;
          "default.clock.max-quantum" = 4096;
        };
      };
    };
    pulseaudio.enable = false;

    # X server (required for NVIDIA compatibility with Wayland)
    xserver = {
      enable = true;
      videoDrivers = ["nvidia"];
      xkb.layout = "us";
    };

    accounts-daemon.enable = true;
    dbus.packages = [pkgs.gcr];

    power-profiles-daemon.enable = false;
    upower.enable = true;

    printing = {
      enable = true;
      drivers = [];
    };

    prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [
        "cpu"
        "diskstats"
        "filesystem"
        "netdev"
        "stat"
        "textfile"
        "time"
        "zfs"
      ];
      listenAddress = "0.0.0.0";
      port = 9100;
    };

    # udev rules for hardware peripherals
    udev = {
      extraRules = ''
        # QMK keyboard rules
        SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ff4", MODE="0666", GROUP="plugdev"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ffb", MODE="0666", GROUP="plugdev"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="174c", ATTRS{idProduct}=="2074", MODE="0666", GROUP="plugdev"

        # Gaming device rules
        SUBSYSTEM=="input", ATTRS{name}=="Rapoo Rapoo Gaming Device", TAG+="uaccess"

        # MSI MYSTIC LIGHT - disable entirely (unused, causes continuous EMI hub resets that disconnect keyboard)
        ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="1462", ATTRS{idProduct}=="7d75", ATTR{authorized}="0"

        # Lock PC on yubikey removal
        ACTION=="remove",\
         ENV{ID_BUS}=="usb",\
         ENV{ID_MODEL_ID}=="0407",\
         ENV{ID_VENDOR_ID}=="1050",\
         ENV{ID_VENDOR}=="Yubico",\
         RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"

        # MT7922: rename wlan0 → wlp13s0 (cfg80211 registers before udev path rename)
        SUBSYSTEM=="net", ACTION=="add", DRIVERS=="mt7921e", ATTR{address}=="02:00:00:00:00:00", NAME="wlp13s0"
      '';
      packages = with pkgs; [
        yubioath-flutter
        yubikey-manager
        yubikey-personalization
      ];
    };
  };

  # =================================================================
  # 6. System Packages (hardware tools)
  # =================================================================
  environment.systemPackages = with pkgs; [
    # Audio & Multimedia
    pavucontrol
    pamixer
    pulseaudio # provides pactl for pipewire-pulse control
    bluez
    bluez-tools
    sof-firmware
    jellyfin-desktop
    libfreeaptx # aptX / aptX HD BT codec
    fdk_aac # AAC BT codec
    ldacbt # LDAC BT codec

    # Graphics & GPU
    libva-utils
    nvidia-vaapi-driver
    vulkan-tools

    # Hardware Support & Monitoring
    apcupsd
    cifs-utils
    fwupd
    microcode-amd
    openrgb-with-all-plugins
    powertop
    samba
    yubikey-personalization
    limine-full

    # Security & Encryption (hardware-backed)
    ccid
    libfido2
    pinentry-all
    yubico-pam
    yubico-piv-tool
    yubioath-flutter
    (pass.withExtensions (exts: [
      exts.pass-checkup
      exts.pass-file
      exts.pass-genphrase
      exts.pass-import
      exts.pass-otp
      exts.pass-update
    ]))
    pass-wayland

    # Secure Boot & EFI Tools
    efibootmgr
    ifrextractor-rs
    sbctl
    sbsigntool
    shim-unsigned
    optnix
  ];

  # =================================================================
  # 7. Networking (host identity & hardware networking)
  # =================================================================
  networking = {
    useDHCP = lib.mkDefault true;
    hostId = "e134040f";
    hostName = "desktop";
    networkmanager = {
      enable = true;
      wifi.backend = "iwd"; # nl80211-only, avoids WEXT deprecation warnings on MT7922
    };
    wireless.iwd = {
      enable = true;
      settings.General.EnableNetworkConfiguration = false; # NM manages connections
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [9100]; # Prometheus node exporter
    };
  };

  # =================================================================
  # 7. Swap Configuration
  # =================================================================
  swapDevices = [];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25; # Use 25% of RAM for zram swap
    priority = 100; # High priority to prefer zram over disk swap
  };

  # =================================================================
  # 8. Systemd Configuration
  # =================================================================
  systemd = {
    coredump.enable = false;
    oomd.enable = true;
    services.bluetooth-unblock = {
      description = "Unblock Bluetooth rfkill soft block";
      wantedBy = ["bluetooth.service"];
      before = ["bluetooth.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
      };
    };
  };

  # =================================================================
  # 9. Platform Configuration
  # =================================================================
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
