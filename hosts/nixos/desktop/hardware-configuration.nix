{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot = {
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

    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;

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

    extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
      # r8169 doesn't support WoL; vendor driver required
      options r8125 disable_wol_support=0 s5wol=1 aspm=0
      # snd-hda-intel index 2 (Ryzen HDA) has no codec connected; fixed PCI probe order 0=NVIDIA,1=AMD-HDMI,2=Ryzen-HDA
      options snd-hda-intel enable=1,1,0
    '';

    supportedFilesystems = ["btrfs"];

    kernelParams = [
      "acpi_enforce_resources=lax" # required for nct6687 hwmon chip access
      "amd_pstate=active"
      # amd_prefcore: only valid value is "disable"; prefcore is on by default with amd_pstate=active
      "microcode.amd_sha_check=off"
      "random.trust_cpu=on"
      "pci=realloc" # fixes chipset PCIe bridge BAR assignment failures at boot

      "amdgpu.dpm=1"

      "mitigations=auto"

      "nvidia-drm.modeset=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"

      "preempt=full"

      "cfg80211.ieee80211_regdom=CA"
      "loglevel=4"
      "nohibernate"
      "rd.systemd.show_status=auto"
      "rd.udev.log_priority=3"
      "usb-storage.delay_use=0"
      "usbcore.autosuspend=-1"

      "video=DP-4:1920x1080@60"
      "video=DP-5:1920x1080@60"

      "amd_iommu=on"
      "iommu=pt"

      # Duplicate pci=realloc: NVIDIA's large VRAM BARs + the stubbed AMD GPU below
      # exhausted PCI address space, leaving RTL8125 (enp12s0) unable to bind.
      "pci=realloc"

      "pci-stub.ids=1022:15e3"
      "transparent_hugepage=madvise"
      "processor.max_cstate=1"
      "irqaffinity=0"
    ];

    kernel.sysctl = {
      "kernel.split_lock_mitigate" = 0;
      "kernel.nmi_watchdog" = 0;

      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;

      "vm.min_free_kbytes" = 1048576;

      # sysctl values, not boot params — don't move to kernelParams
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";

      "net.core.busy_poll" = 50;
      "net.core.busy_read" = 50;
      "net.core.netdev_budget" = 600;
      "net.core.netdev_max_backlog" = 5000;

      "net.core.rmem_default" = 262144;
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_default" = 262144;
      "net.core.wmem_max" = 16777216;

      "net.ipv4.ip_local_port_range" = "1024 65535";

      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_rmem" = "4096 65536 16777216";
      "net.ipv4.tcp_sack" = 1;
      "net.ipv4.tcp_timestamps" = 1;
      "net.ipv4.tcp_tw_reuse" = 1;
      "net.ipv4.tcp_window_scaling" = 1;
      "net.ipv4.tcp_wmem" = "4096 65536 16777216";
    };

    tmp.useTmpfs = true;
    tmp.tmpfsSize = "100%";
    tmp.tmpfsHugeMemoryPages = "within_size";
  };

  # tmpfs: compilers (rustc, gcc, clang, go) write large intermediates here
  fileSystems."/var/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "size=16G"
      "mode=1777"
      "noatime"
    ];
  };

  hardware = {
    amdgpu.overdrive.enable = true;

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

    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    enableRedistributableFirmware = lib.mkDefault true;

    gpgSmartcards.enable = true;

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        rocmPackages.clr
        rocmPackages.clr.icd
      ];
    };

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
      secureBoot.enable = false; # TODO: re-enable after first boot once sbctl keys are generated + enrolled
      additionalFiles = {
        # Firmware's built-in UEFI Shell is stripped-down and breaks MSI's svet.efi
        # flashing script; this provides a full Tianocore EDK2 shell instead. See docs/efi.md.
        "efi/BOOT/shell.efi" = "${pkgs.edk2-uefi-shell}/shell.efi";
      };
      extraEntries = ''
        /UEFI Shell
            protocol: efi_chainload
            path: boot():/efi/BOOT/shell.efi
      '';
      style.wallpapers = [
        "${builtins.path {
          path = ./boot/background.jpg;
          name = "limine-background.jpg";
        }}"
      ];
    };
  };

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

  # commit ba41835 in linux-firmware broke mt7921e init; pin the two firmware blobs
  # to pre-ba41835 (20250808). https://github.com/NixOS/nixpkgs/issues/444538
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

  programs = {
    noisetorch.enable = true;
  };

  services = {
    # scx_lavd --performance previously froze the desktop under game load (disables
    # Core Compaction, pins cores to max freq); autopilot mode + gamemode swapping to
    # scx_bpfland on game launch (modules/gaming/default.nix) avoids it.
    scx-loader = {
      enable = true;
      config = {
        default_sched = "scx_lavd";
        default_mode = "Auto";
      };
    };

    smartd = {
      autodetect = true;
      defaults.autodetected = "-a -o on -s (S/../.././02|L/../../7/04)";
      enable = true;
    };

    ucodenix = {
      enable = true;
      cpuModelId = ./facter.json;
    };

    btrfs.autoScrub = {
      enable = true;
      interval = "weekly";
      fileSystems = ["/"];
    };
    fstrim = {
      enable = true;
      interval = "weekly";
    };

    fwupd = {
      enable = true;
      extraRemotes = [
        "lvfs-testing"
        "vendor"
      ];
    };

    pcscd = {
      enable = true;
      plugins = [pkgs.ccid];
    };

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
          # Card does up to 192 kHz natively; list both families so hi-res FLAC
          # plays without resampling.
          default.clock.allowed-rates = [
            44100
            48000
            88200
            96000
            176400
            192000
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
    dbus.packages = [pkgs.gcr_4];

    # irqbalance fights isolcpus=1-11 + irqaffinity=0 — disable it
    irqbalance.enable = false;

    power-profiles-daemon.enable = false;
    upower.enable = true;

    printing = {
      enable = true;
      drivers = [];
    };

    udev = {
      extraRules = ''
        SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ff4", MODE="0666", GROUP="plugdev"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ffb", MODE="0666", GROUP="plugdev"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="174c", ATTRS{idProduct}=="2074", MODE="0666", GROUP="plugdev"

        SUBSYSTEM=="input", ATTRS{name}=="Rapoo Rapoo Gaming Device", TAG+="uaccess"

        ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="1462", ATTRS{idProduct}=="7d75", ATTR{authorized}="0"

        ACTION=="remove", \
          ENV{ID_BUS}=="usb", \
          ENV{ID_MODEL_ID}=="0407", \
          ENV{ID_VENDOR_ID}=="1050", \
          ENV{ID_VENDOR}=="Yubico", \
          RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"

        # ENV{DEVTYPE}!="partition" avoids errors on partition nodes, which have no queue/ sysfs dir
        ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ENV{DEVTYPE}!="partition", ATTR{queue/scheduler}="kyber"
        ACTION=="add|change", KERNEL=="sd[a-z]", ENV{DEVTYPE}!="partition", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="kyber"
        ACTION=="add|change", KERNEL=="sd[a-z]", ENV{DEVTYPE}!="partition", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"

        ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ENV{DEVTYPE}!="partition", ATTR{queue/nr_requests}="1024"
      '';
      # Must be a lower-numbered rules file than 98-ipv6-privacy-extensions.rules so
      # $name is already "wlp13s0" when that rule's RUN fires; extraRules (99-local.rules) is too late.
      packages =
        [
          (pkgs.writeTextFile {
            name = "70-mt7922-rename.rules";
            destination = "/etc/udev/rules.d/70-mt7922-rename.rules";
            text = ''
              SUBSYSTEM=="net", ACTION=="add", DRIVERS=="mt7921e", ATTR{address}=="${config.my.network.mac.desktop-wifi}", NAME="wlp13s0"
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

  environment.systemPackages = with pkgs; [
    pavucontrol
    pamixer
    pulseaudio # provides pactl for pipewire-pulse control
    bluez
    bluez-tools
    sof-firmware
    libfreeaptx # aptX / aptX HD BT codec
    fdk_aac # AAC BT codec
    ldacbt # LDAC BT codec

    libva-utils
    nvidia-vaapi-driver
    vulkan-tools

    anydesk
    teamviewer

    apcupsd
    cifs-utils
    fwupd
    microcode-amd
    powertop
    samba
    stress-ng # additional stress-test backends for coolercontrol
    yubikey-personalization
    limine-full

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

    efibootmgr
    ifrextractor-rs
    sbctl
    sbsigntool
    optnix
    # efitools
    # shim-unsigned
  ];

  # nixos-facter-modules force-enables per-interface useDHCP independent of
  # networking.useDHCP, which flips on global dhcpcd and races NetworkManager's
  # own DHCP client (dhcp6 EADDRINUSE) — disable facter's auto-DHCP entirely.
  facter.detected.dhcp.enable = lib.mkForce false;

  networking = {
    useDHCP = lib.mkDefault false; # NetworkManager owns DHCP for enp12s0; global dhcpcd was racing it (ARP defence failures, dhcp6 EADDRINUSE)
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

  swapDevices = [];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
    priority = 100; # High priority to prefer zram over disk swap
  };

  systemd = {
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
