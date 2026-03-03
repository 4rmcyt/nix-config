{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
{
  my.desktop = {
    windowManager = "niri"; # Options: "hyprland", "niri", "none"
    displayManager = "greetd"; # Options: "greetd", "sddm", "gdm", "none"
  };

  # =================================================================
  # 1. Imports
  # =================================================================
  imports = [
    # Hardware and system base
    ./hardware-configuration.nix
    ../../../modules/base
    ../../../modules/disko/desktop
    ../../../modules/options
    ../../../modules/fonts

    # Desktop environment
    # ../../../modules/DE/kde

    # Features and roles
    ../../../modules/gaming
    ../../../modules/networking/dnssec
    ../../../modules/networking/ssh
    ../../../modules/networking/nut-client
    ../../../modules/networking/avahi

    # TUI
    ../../../modules/TUI/tty.nix
    ../../../modules/users/zeev
    # llama-cpp moved to HM-level (modules/TUI/ai-tools/llama-cpp)
    # ../../../modules/TUI/litellm
    # mcp moved to HM-level (home/desktop)
    # ../../../modules/GUI/OBS
    ../../../modules/GUI/chromium
    ../../../modules/GUI/flatpak/hyprland
    ../../../modules/xdg
  ];

  # =================================================================
  # 2. System Configuration
  # =================================================================
  system.stateVersion = "25.05";

  # =================================================================
  # 3. Secrets Management
  # =================================================================
  sops = {
    secrets = {
      tailscale_auth_key = {
        sopsFile = ../../../secrets/tailscale-desktop.yaml;
        key = "tailscale_auth_key";
      };
      git_access_token = {
        sopsFile = ../../../secrets/common.yaml;
        key = "git_access_token";
      };
      gemini_api_key = {
        sopsFile = ../../../secrets/common.yaml;
        key = "gemini_api_key";
        owner = "zeev";
        group = "users";
      };
    };

    age.keyFile = "/root/.config/sops/age/keys.txt";
  };

  # =================================================================
  # 4. Boot Configuration
  # =================================================================
  boot = {
    kernelParams = [
      "usbcore.quirks=1462:7d75:gki" # MSI MYSTIC LIGHT: g=ignore GetStringDescriptor, k=no autosuspend, i=ignore device
      "video=DP-4:1920x1080@60"
      "video=DP-5:1920x1080@60"
    ];

    loader = {
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
  };

  # =================================================================
  # 5. Nixpkgs Configuration
  # =================================================================
  nixpkgs.config.cudaSupport = true;

  # =================================================================
  # =================================================================
  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };

  # PAM U2F configuration
  security.pam.u2f = {
    enable = true;
    control = "optional";
    settings = {
      authfile = "/etc/u2f_mappings";
      cue = true;
    };
  };

  # =================================================================
  # 6. Nix Configuration
  # =================================================================

  nix = {
    package = pkgs.lixPackageSets.latest.lix;
    channel.enable = false;
    registry.nixpkgs.flake = inputs.nixpkgs;
    settings = {
      cores = 0;
      experimental-features = [
        "flakes"
        "nix-command"
        "auto-allocate-uids"
      ];
      auto-optimise-store = true;
      warn-dirty = false;
      max-jobs = 8;
      keep-going = true; # Continue building other derivations on failure
      max-substitution-jobs = 16;
      http-connections = 25;
      connect-timeout = 5;
      keep-outputs = true;
      keep-derivations = true;
      min-free = 5368709120; # 5GB - trigger GC when less than 5GB free
      max-free = 10737418240; # 10GB - stop GC when 10GB free
      builders-use-substitutes = true;
      require-sigs = true;
      eval-cache = true;
      extra-system-features = [
        "big-parallel"
        "kvm"
      ];
      trusted-users = [
        "root"
        "@wheel"
        "nix-builder"
      ];
    };
  };

  # =================================================================
  # 7. Environment
  # =================================================================
  environment = {
    sessionVariables = lib.mkBefore {
      # GPG Agent for SSH (uses gpg-agent socket)
      SSH_AUTH_SOCK = "/run/user/\${UID}/gnupg/S.gpg-agent.ssh";

      # Cursor theme
      XCURSOR_THEME = "breeze_cursors";
      XCURSOR_SIZE = "24";

      # XDG
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";

      # Add home-manager and flatpak paths for fonts and icons in all sessions (including TTY)
      XDG_DATA_DIRS = lib.mkAfter [
        "$HOME/.nix-profile/share"
        "$HOME/.local/share/flatpak/exports/share"
        "/var/lib/flatpak/exports/share"
      ];
    };

    shells = lib.mkBefore (
      with pkgs;
      [
        zsh
        nushell
      ]
    );

    systemPackages = lib.mkBefore (
      with pkgs;
      [
        # =============================================================
        # Audio & Multimedia
        # =============================================================
        helvum
        pavucontrol # PulseAudio Volume Control
        pamixer # Command-line mixer for PulseAudio
        bluez # Bluetooth support
        bluez-tools # Bluetooth tools
        sof-firmware
        inputs.nixos-jellyfin.packages.x86_64-linux.jellyfin-desktop

        # =============================================================
        # Fonts & Themes
        # =============================================================
        fira-code
        fira-mono
        meslo-lgs-nf
        nerd-fonts.droid-sans-mono
        nerd-fonts.fira-code

        # =============================================================
        # Graphics & GPU
        # =============================================================
        libva-utils
        nvidia-vaapi-driver
        vulkan-tools

        # =============================================================
        # Hardware Support & Monitoring
        # =============================================================
        apcupsd
        cifs-utils
        fwupd
        microcode-amd
        openrgb-with-all-plugins
        powertop
        # ryzen-monitor-ng
        samba
        yubikey-personalization
        limine-full
        # clan-cli

        # =============================================================
        # Security & Encryption
        # =============================================================
        ccid
        libfido2
        (pass.withExtensions (exts: [
          exts.pass-checkup
          exts.pass-file
          exts.pass-genphrase
          exts.pass-import
          exts.pass-otp
          exts.pass-update
        ]))
        pass-wayland
        pinentry-all
        yubico-pam
        yubico-piv-tool
        yubioath-flutter

        # =============================================================
        # Secure Boot & EFI Tools
        # =============================================================
        efibootmgr
        ifrextractor-rs
        sbctl
        sbsigntool
        shim-unsigned
        optnix

        # =============================================================
        # Lix Tooling
        # =============================================================
        lixPackageSets.latest.nixpkgs-review
        lixPackageSets.latest.nix-eval-jobs
        lixPackageSets.latest.nix-fast-build
        lixPackageSets.latest.colmena
        lixPackageSets.latest.nix-direnv
      ]
    );
  };

  # =================================================================
  # 8. Fonts
  # =================================================================
  fonts = {
    fontDir.enable = true;
    fontconfig = {
      enable = true;
      useEmbeddedBitmaps = true;
      defaultFonts = {
        monospace = [
          "JetBrainsMono Nerd Font"
          "Fira Code"
        ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
    packages =
      with pkgs;
      [
        maple-mono.NF
        font-awesome
        noto-fonts
        noto-fonts-color-emoji
      ]
      ++ (builtins.filter lib.isDerivation (lib.attrValues pkgs.nerd-fonts));
  };

  # =================================================================
  # 9. Hardware
  # =================================================================
  hardware.amdgpu.overdrive.enable = true;

  # Firmware packages (includes MT7922 WiFi firmware)
  # Custom uncompressed MT7922 firmware to avoid "Direct firmware load failed" warnings
  hardware.firmware =
    let
      mt7922-firmware-uncompressed =
        pkgs.runCommand "mt7922-firmware-uncompressed"
          {
            nativeBuildInputs = [ pkgs.zstd ];
          }
          ''
            mkdir -p $out/lib/firmware/mediatek
            for file in ${pkgs.linux-firmware}/lib/firmware/mediatek/WIFI_RAM_CODE_MT7922*.bin.zst \
                        ${pkgs.linux-firmware}/lib/firmware/mediatek/WIFI_MT7922*.bin.zst; do
              if [ -f "$file" ]; then
                base=$(basename "$file" .zst)
                zstd -d "$file" -o "$out/lib/firmware/mediatek/$base"
              fi
            done
          '';
    in
    [
      mt7922-firmware-uncompressed
      pkgs.linux-firmware
    ];

  # =================================================================
  # 10. Home Manager
  # =================================================================
  # backupFileExtension is set in commonHomeManagerNixosConfig with unique timestamp

  # =================================================================
  # 11. Networking
  # =================================================================
  networking = {
    dnssec = {
      enable = true;
      profileId = "nextdns0";
    };
    enableIPv6 = false;
    firewall = {
      allowedTCPPorts = [ 9100 ]; # Prometheus node exporter
      enable = true;
    };
    hostId = "e134040f";
    hostName = "desktop";
    networkmanager.enable = true;
  };

  # =================================================================
  # 12. Programs
  # =================================================================
  programs = {
    corectrl.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-all;
    };

    nh = {
      clean.enable = true;
      clean.extraArgs = "--keep-since 10d --keep 3";
      enable = true;
      flake = "/home/zeev/src/nix-config";
    };

    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    zsh.enable = true;

    nix-ld.enable = true;

    noisetorch.enable = true;
    # vscode.enable = true;

    virt-manager.enable = true;
  };

  # =================================================================
  # 13. Services
  # =================================================================
  # Greetd Autologin Configuration
  # =================================================================
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.niri}/bin/niri --session";
        user = "zeev";
      };
    };
  };

  # =================================================================
  services = {
    # =============================================================
    # Display Manager
    # =============================================================
    gnome.gnome-keyring.enable = true;

    # =============================================================
    # Audio Services
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
        "stream.properties" = {
          "node.max-latency" = "1/60";
        };
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

    # =============================================================
    # File Systems & Storage
    # =============================================================
    davfs2 = {
      enable = true;
      settings = {
        sections = {
          "/data/zeev/Taildrive" = {
            gui_optimize = true;
          };
        };
      };
    };

    # =============================================================
    # Hardware Services
    # =============================================================
    auto-cpufreq = {
      enable = true;
      settings.charger = {
        governor = "performance";
        turbo = "auto";
      };
    };

    fwupd = {
      enable = true;
      extraRemotes = [
        "lvfs-testing"
        "vendor"
      ];
    };

    openssh.enable = true;

    pcscd = {
      enable = true;
      plugins = [ pkgs.ccid ];
    };

    accounts-daemon.enable = true;
    dbus.packages = [ pkgs.gcr ];

    # Power management
    power-profiles-daemon.enable = false;
    upower.enable = true;

    # Printing
    printing = {
      enable = true;
      drivers = [ ]; # Add printer drivers if needed
    };

    usbmuxd.enable = true;

    # =============================================================
    # Monitoring Services
    # =============================================================
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

    # =============================================================
    # Networking Services
    # =============================================================
    tailscale = {
      authKeyFile = config.sops.secrets.tailscale_auth_key.path;
      enable = true;
      useRoutingFeatures = "both";
      extraUpFlags = [ "--accept-routes" ];
    };

    # =============================================================
    # Hardware Peripherals
    # =============================================================
    udev = {
      extraRules = ''
        # QMK keyboard rules
        SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ff4", MODE="0666", GROUP="plugdev"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2ffb", MODE="0666", GROUP="plugdev"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="174c", ATTRS{idProduct}=="2074", MODE="0666", GROUP="plugdev"

        # Gaming device rules
        SUBSYSTEM=="input", ATTRS{name}=="Rapoo Rapoo Gaming Device", TAG+="uaccess"

        # MSI MYSTIC LIGHT - Keep power management disabled (handled by kernel quirk)
        ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="1462", ATTRS{idProduct}=="7d75", TEST=="power/control", ATTR{power/control}="on"

        # Lock PC on yubikey removal
        ACTION=="remove",\
         ENV{ID_BUS}=="usb",\
         ENV{ID_MODEL_ID}=="0407",\
         ENV{ID_VENDOR_ID}=="1050",\
         ENV{ID_VENDOR}=="Yubico",\
         RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
      '';
      packages = with pkgs; [
        yubioath-flutter
        yubikey-manager
        yubikey-personalization
      ];
    };

    # =============================================================
    # X Server (for NVIDIA compatibility)
    # =============================================================
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      xkb.layout = "us";
    };
  };
  # =================================================================
  # 14. Users & Groups
  # =================================================================
  users = {
    groups = {
      git = { };
      plugdev = { };
      prometheus = { };
      nix-builder = { };
    };

    users = {
      git = {
        createHome = true;
        description = "Git user";
        group = "git";
        home = "/var/lib/git";
        isSystemUser = true;
        shell = pkgs.nushell;
      };

      prometheus = {
        description = "Prometheus daemon user";
        group = "prometheus";
        isSystemUser = true;
      };

      # User for accepting remote nix builds
      nix-builder = {
        isSystemUser = true;
        group = "nix-builder";
        description = "Nix remote builder user";
        home = "/var/lib/nix-builder";
        createHome = true;
        shell = pkgs.bash;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ6N/kA0Cx1Swre7mQzWvqxL2o4TvD3l0hrAiNr0Qkcp nix-builder@homeserver"
        ];
      };

      zeev.shell = lib.mkForce pkgs.zsh;
    };
  };

  # =================================================================
  # 15. Virtualization
  # =================================================================
  virtualisation = {
    podman.enable = true;
    libvirtd = {
      enable = true;
      qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
    };
    spiceUSBRedirection.enable = true;
  };

  systemd.tmpfiles.rules = [
    "d /data/zeev/Taildrive 770 davfs2 users -"
  ];
}
