{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: let
  xanmodKernel = pkgs.linuxKernel.packages.linux_zen;
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
      "r8125"
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
      "r8125"
      "snd-usb-audio"
      "snd_hda_codec_hdmi"
      "snd_hda_intel"
      "v4l2loopback"
      "nct6687"
      "zenergy"
    ];

    kernelPackages = assert !xanmodKernel.${pkgs.zfs.kernelModuleAttribute}.meta.broken; xanmodKernel;

    blacklistedKernelModules = [
      "r8169"
      "nct6683"
    ];

    extraModulePackages = with config.boot.kernelPackages; [
      r8125
      v4l2loopback
      zenergy
      ryzen-smu
      nct6687d
    ];

    # Module configuration
    extraModprobeConfig = ''
      # Enable v4l2loopback for virtual camera
      options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
      # RTL8125: vendor driver required for WoL (r8169 doesn't support it)
      options r8125 disable_wol_support=0 s5wol=1 aspm=0
      # Disable snd-hda-intel index 2 (0000:10:00.6, Ryzen HD Audio Controller) — no codec connected
      # PCI probe order is fixed: 01:00.1=NVIDIA(0), 10:00.1=AMD-HDMI(1), 10:00.6=Ryzen-HDA(2)
      options snd-hda-intel enable=1,1,0
      # ZFS ARC max: 24GB (40% of 62GB RAM) — canonical modprobe form, not cmdline
      options zfs zfs_arc_max=25769803776
    '';

    supportedFilesystems = ["zfs"];

    # Kernel parameters
    kernelParams = [
      "acpi_enforce_resources=lax" # Required for nct6687 hwmon chip access
      "amd_pstate=active" # Use CPPC EPP driver for best Zen 4 performance
      # amd_prefcore: only valid value is "disable"; prefcore is on by default with amd_pstate=active
      "microcode.amd_sha_check=off"
      "random.trust_cpu=on"

      "amdgpu.dpm=1" # Enable dynamic power management

      "mitigations=auto"

      "nvidia-drm.modeset=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"

      "preempt=full" # Full preemption for desktop responsiveness

      # System configuration
      "cfg80211.ieee80211_regdom=CA"
      "loglevel=4"
      "nohibernate"
      "rd.systemd.show_status=auto"
      "rd.udev.log_priority=3"
      "usb-storage.delay_use=0"
      "usbcore.autosuspend=-1"

      # Display output hints for early modesetting
      "video=DP-4:1920x1080@60"
      "video=DP-5:1920x1080@60"

      "amd_iommu=on"
      "iommu=pt"

      "pci-stub.ids=1022:15e3"
      "transparent_hugepage=madvise"
      "processor.max_cstate=1"
      "irqaffinity=0" # Force hardware interrupts to Core 0 where possible
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
      # dirty_ratio omitted: ZFS bypasses the kernel page cache (uses ARC directly);
      # these only affect tmpfs/non-ZFS paths where defaults are fine

      # ZFS-specific optimizations for Zen 4
      "vm.min_free_kbytes" = 1048576; # 1GB min free for ZFS ARC stability

      # Network — moved from kernelParams (these are sysctl values, not boot params)
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";

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

    # Tmp configuration
    tmp.useTmpfs = true;
    tmp.tmpfsSize = "100%";
    tmp.tmpfsHugeMemoryPages = "within_size";
  };

  # /var/tmp on tmpfs — compilers (rustc, gcc, clang, go) write large intermediates here
  fileSystems."/var/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "size=16G"
      "mode=1777"
      "noatime"
    ];
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
          FastConnectable = true;
        };
        Policy = {
          AutoEnable = true;
          ReconnectAttempts = 3;
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
      powerManagement = {
        enable = true;
        finegrained = false;
      };
    };

    uinput.enable = true;
  };

  # bap plugin disabled via -P flag — DisablePlugins is not a valid main.conf key
  systemd.services.bluetooth.serviceConfig.ExecStart = [
    ""
    "${pkgs.bluez}/libexec/bluetooth/bluetoothd -f /etc/bluetooth/main.conf -P bap"
  ];

  powerManagement.cpuFreqGovernor = "performance";

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
      efiSupport = true;
      efiInstallAsRemovable = false;
      biosSupport = false;
      secureBoot.enable = true;
      style.wallpapers = [
        "${builtins.path {
          path = ./boot/background.jpg;
          name = "limine-background.jpg";
        }}"
      ];
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
  # linux-firmware uses .zst compression, so we fetch the pre-compressed blobs.
  # https://github.com/NixOS/nixpkgs/issues/444538
  nixpkgs.overlays = [
    (_final: prev: {
      linux-firmware = prev.linux-firmware.overrideAttrs (old: {
        postInstall =
          (old.postInstall or "")
          + ''
            cp ${
              prev.fetchurl {
                url = "https://gitlab.com/kernel-firmware/linux-firmware/-/raw/20250808/mediatek/WIFI_RAM_CODE_MT7922_1.bin";
                sha256 = "19jfkmpqngm0d3wpv2inc9hmmqjfk5nhbw5d6mkvh23idg3w2jm3";
              }
            } $out/lib/firmware/mediatek/WIFI_RAM_CODE_MT7922_1.bin.tmp
            ${prev.zstd}/bin/zstd -f -19 $out/lib/firmware/mediatek/WIFI_RAM_CODE_MT7922_1.bin.tmp -o $out/lib/firmware/mediatek/WIFI_RAM_CODE_MT7922_1.bin.zst
            rm $out/lib/firmware/mediatek/WIFI_RAM_CODE_MT7922_1.bin.tmp
            cp ${
              prev.fetchurl {
                url = "https://gitlab.com/kernel-firmware/linux-firmware/-/raw/20250808/mediatek/WIFI_MT7922_patch_mcu_1_1_hdr.bin";
                sha256 = "1q4irdjmbfpx8fsv8qiprzklvm62z614vchyjnhpbh2745bxl65y";
              }
            } $out/lib/firmware/mediatek/WIFI_MT7922_patch_mcu_1_1_hdr.bin.tmp
            ${prev.zstd}/bin/zstd -f -19 $out/lib/firmware/mediatek/WIFI_MT7922_patch_mcu_1_1_hdr.bin.tmp -o $out/lib/firmware/mediatek/WIFI_MT7922_patch_mcu_1_1_hdr.bin.zst
            rm $out/lib/firmware/mediatek/WIFI_MT7922_patch_mcu_1_1_hdr.bin.tmp
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

    # SCX Scheduler — scx_lavd: LAVD algorithm, designed for gaming/interactive
    # workloads on single-CCX Zen 4; --performance disables DVFS throttling
    scx = {
      enable = true;
      package = pkgs.scx.full;
      scheduler = "scx_lavd";
      extraArgs = ["--performance"];
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

    # # CPU frequency scaling
    # auto-cpufreq = {
    #   enable = true;
    #   settings.charger = {
    #     governor = "performance";
    #     turbo = "auto";
    #   };
    # };

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
        context.modules = [
          {
            name = "libpipewire-module-rt";
            args = {
              "nice.level" = -11;
              "rt.prio" = 88;
              "rt.time.soft" = 200000;
              "rt.time.hard" = 200000;
            };
            flags = [
              "ifexists"
              "nofail"
            ];
          }
        ];
        context.properties = {
          default.clock.rate = 48000;
          default.clock.allowed-rates = [
            44100
            48000
          ];
          default.clock.quantum = 1024;
          default.clock.min-quantum = 32;
          default.clock.max-quantum = 8192;
        };
      };
      extraConfig.pipewire."93-screen-share" = {
        "stream.properties"."node.max-latency" = "1/60";
        context.spa-libs = {
          "api.libcamera.*" = "libcamera/libspa-libcamera";
          "support.*" = "support/libspa-support";
        };
      };
    };
    pulseaudio.enable = false;

    xserver = {
      enable = true;
      videoDrivers = ["nvidia"];
      xkb.layout = "us";
    };

    accounts-daemon.enable = true;
    dbus.packages = [pkgs.gcr];

    # irqbalance fights isolcpus=1-11 + irqaffinity=0 — disable it
    irqbalance.enable = false;

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

        # MSI MYSTIC LIGHT - disable entirely
        # Changed DEVTYPE to ENV{DEVTYPE} for schema compliance
        ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="1462", ATTRS{idProduct}=="7d75", ATTR{authorized}="0"

        # Lock PC on yubikey removal
        # Added spaces after commas and corrected line continuation spacing
        ACTION=="remove", \
          ENV{ID_BUS}=="usb", \
          ENV{ID_MODEL_ID}=="0407", \
          ENV{ID_VENDOR_ID}=="1050", \
          ENV{ID_VENDOR}=="Yubico", \
          RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"

        # I/O scheduler: kyber for NVMe/SSD (low-latency), bfq for HDD
        # ENV{DEVTYPE}!="partition" prevents errors on partition nodes which have no queue/ sysfs dir
        ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ENV{DEVTYPE}!="partition", ATTR{queue/scheduler}="kyber"
        ACTION=="add|change", KERNEL=="sd[a-z]", ENV{DEVTYPE}!="partition", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"
        ACTION=="add|change", KERNEL=="sd[a-z]", ENV{DEVTYPE}!="partition", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"

        # NVMe queue depth: increase from default 128 for better throughput under ZFS
        ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ENV{DEVTYPE}!="partition", ATTR{queue/nr_requests}="1024"
      '';
      # MT7922 rename must be in a lower-numbered file than 98-ipv6-privacy-extensions.rules
      # so that $name is already "wlp13s0" when the IPv6 rule's RUN fires.
      # extraRules goes to 99-local.rules which is too late — use packages instead.
      packages =
        [
          (pkgs.writeTextFile {
            name = "70-mt7922-rename.rules";
            destination = "/etc/udev/rules.d/70-mt7922-rename.rules";
            text = ''
              SUBSYSTEM=="net", ACTION=="add", DRIVERS=="mt7921e", ATTR{address}=="02:00:00:00:00:00", NAME="wlp13s0"
            '';
          })
        ]
        ++ (with pkgs; [
          yubioath-flutter
          yubikey-manager
          yubikey-personalization
          game-devices-udev-rules
        ]);
    };
  };

  # =================================================================
  # 8. System Packages (hardware tools)
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
    optnix
    # efitools
    # shim-unsigned
  ];

  # =================================================================
  # 9. Networking (host identity & hardware networking)
  # =================================================================
  networking = {
    useDHCP = lib.mkDefault true;
    hostId = "e134040f";
    hostName = "desktop";
    networkmanager = {
      enable = true;
      wifi.backend = "iwd"; # nl80211-only, avoids WEXT deprecation warnings on MT7922
      settings = {
        "connection-enp12s0" = {
          "match-device" = "interface-name:enp12s0";
          "ethernet.wake-on-lan" = "magic";
        };
        # Prevent NM from managing iwd P2P devices — avoids IPv4 forwarding race at boot
        "device-iwd-p2p" = {
          "match-device" = "type:wifi-p2p";
          "managed" = "false";
        };
      };
    };
    wireless.iwd = {
      enable = true;
      settings.General.EnableNetworkConfiguration = false; # NM manages connections
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [
        9100
        9
      ];
    };
  };

  # =================================================================
  # 10. Swap Configuration
  # =================================================================
  swapDevices = [];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25; # Use 25% of RAM for zram swap
    priority = 100; # High priority to prefer zram over disk swap
  };

  # =================================================================
  # 11. Systemd Configuration
  # =================================================================
  systemd = {
    coredump.enable = false;
    oomd.enable = false;
    services.bluetooth-unblock = {
      description = "Unblock Bluetooth rfkill soft block";
      wantedBy = ["bluetooth.service"];
      before = ["bluetooth.service"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
      };
    };

    services.wowlan-enable = {
      description = "Enable Wake-on-Wireless LAN magic packet on wlp13s0";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.iw}/bin/iw phy phy0 wowlan enable magic-packet";
      };
    };
  };

  # Rapoo Gaming Device: disable button debounce to suppress libinput timer lag warnings
  environment.etc."libinput/local-overrides.quirks".text = ''
    [Rapoo Gaming Device]
    MatchName=Rapoo Rapoo Gaming Device
    ModelBouncingKeys=1
  '';

  # =================================================================
  # 9. Platform Configuration
  # =================================================================
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  systemd.services.numlock = {
    description = "Enable numlock on TTYs";
    wantedBy = ["multi-user.target"];
    after = ["systemd-vconsole-setup.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'for tty in /dev/tty{1..6}; do ${pkgs.kbd}/bin/setleds -D +num < $tty; done'";
    };
  };
}
