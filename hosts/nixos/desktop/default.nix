{
  pkgs,
  config,
  lib,
  ...
}: let
  zfsExcludes = lib.concatMapStringsSep " " (p: "--exclude-prefix=${p}") [
    "/dev"
    "/var/empty"
    "/nix/var/nix/temproots"
    "/nix/var/nix/b"
    "/var/lib/containers/storage/tmp"
    "/var/lib/cni/networks"
    "/var/lib/systemd/ephemeral-trees"
    "/var/lib/systemd/coredump"
  ];
in {
  my.desktop = {
    windowManager = "niri"; # Options: "hyprland", "niri", "none"
    displayManager = "greetd"; # Options: "greetd", "sddm", "gdm", "none"
  };

  # =================================================================
  # Imports
  # =================================================================
  imports = [
    # Hardware and system base
    ./hardware-configuration.nix
    ../../../modules/base
    ../../../modules/base/logging/desktop.nix
    ../../../modules/disko/desktop
    ../../../modules/fonts
    ../../../modules/options

    # Features and roles
    ../../../modules/gaming
    # ../../../modules/networking/avahi
    ../../../modules/networking/dnssec
    ../../../modules/networking/nfs-client
    ../../../modules/networking/nut-client
    ../../../modules/networking/ssh

    # Users & GUI
    ../../../modules/GUI/chrome
    ../../../modules/GUI/flatpak/hyprland
    ../../../modules/GUI/nautilus
    ../../../modules/GUI/virt-manager
    ../../../modules/GUI/waydroid
    ../../../modules/TUI/tty.nix
    ../../../modules/users/zeev
    ../../../modules/xdg
  ];

  # =================================================================
  # Secrets Management
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
        owner = "root";
      };
      gemini_api_key = {
        sopsFile = ../../../secrets/common.yaml;
        key = "gemini_api_key";
        owner = "zeev";
      };
    };

    age.keyFile = "/root/.config/sops/age/keys.txt";
  };

  # =================================================================
  # Nix Configuration
  # =================================================================

  nix.settings = {
    cores = 0;
    max-jobs = "auto";
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

  # =================================================================
  # Environment
  # =================================================================
  environment = {
    sessionVariables = lib.mkBefore {
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

    shells = lib.mkBefore (with pkgs; [zsh]);

    systemPackages = with pkgs; [
      # Dev workstation tools (not on all hosts)
      ansible
      awscli2
      s3cmd
      opentofu
      terraform
      gradle
      kotlin
      ktlint
      prometheus # promtool linter
      iw

      # Lix Tooling
      lixPackageSets.latest.nixpkgs-review
      lixPackageSets.latest.nix-eval-jobs
      lixPackageSets.latest.nix-fast-build
      lixPackageSets.latest.colmena
      lixPackageSets.latest.nix-direnv
      lixPackageSets.latest.nix-serve-ng
      lixPackageSets.latest.boehmgc
      lixPackageSets.latest.nil
      lixPackageSets.latest.nurl
      lixPackageSets.latest.nix-init
      lixPackageSets.latest.nix-update
    ];
  };

  # =================================================================
  # Fonts
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
        sansSerif = ["Noto Sans"];
        serif = ["Noto Serif"];
        emoji = ["Noto Color Emoji"];
      };
    };
    packages = with pkgs;
      [
        maple-mono.NF
        font-awesome
        noto-fonts
        noto-fonts-color-emoji
      ]
      ++ (builtins.filter lib.isDerivation (lib.attrValues pkgs.nerd-fonts));
  };

  # =================================================================
  # Networking
  # =================================================================
  networking = {
    dnssec = {
      enable = true;
      profileId = "nextdns0";
    };
    enableIPv6 = false;
    interfaces.enp12s0.wakeOnLan.enable = true;
  };

  # =================================================================
  # Programs
  # =================================================================
  programs.nix-ld.enable = true;

  # =================================================================
  # Services
  # =================================================================

  security.pam.services.greetd.enableGnomeKeyring = true;

  environment.etc."xdg/autostart/gnome-keyring-secrets.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Secret Storage Service
    Hidden=true
  '';

  services = {
    gnome.gnome-keyring.enable = true;

    # davfs2 = {
    #   enable = true;
    #   settings.sections."/data/zeev/Taildrive".gui_optimize = true;
    # };

    openssh.enable = true;

    tailscale = {
      authKeyFile = config.sops.secrets.tailscale_auth_key.path;
      enable = true;
      useRoutingFeatures = "both";
      extraUpFlags = ["--accept-routes" "--accept-dns=false"];
    };
  };
  # =================================================================
  # Users & Groups
  # =================================================================
  users = {
    groups = {
      git = {};
      plugdev = {};
      prometheus = {};
      nix-builder = {};
    };

    users = {
      git = {
        createHome = true;
        description = "Git user";
        group = "git";
        home = "/var/lib/git";
        isSystemUser = true;
        shell = pkgs.bash;
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

  systemd.tmpfiles.rules = [
    "d /home/zeev/.local/share/Trash 0700 zeev users -"
    "d /home/zeev/.local/share/Trash/files 0700 zeev users -"
    "d /home/zeev/.local/share/Trash/info 0700 zeev users -"
  ];

  # ZFS does not support FS_IOC_SETFLAGS (chattr), causing "Protocol driver not attached"
  # warnings from systemd-tmpfiles for any path that uses the 'h' rule (chattr immutable).
  # Suppress by excluding all such paths from all tmpfiles services.
  systemd.services.systemd-tmpfiles-setup.serviceConfig.ExecStart = [
    ""
    "systemd-tmpfiles --create --remove --boot ${zfsExcludes}"
  ];
  systemd.services.systemd-tmpfiles-resetup.serviceConfig.ExecStart = [
    ""
    "systemd-tmpfiles --create ${zfsExcludes}"
  ];
  systemd.services.systemd-tmpfiles-clean.serviceConfig.ExecStart = [
    ""
    "systemd-tmpfiles --clean ${zfsExcludes}"
  ];

  # Restrict avahi to ethernet only — both enp12s0 and wlp13s0 probing simultaneously
  # causes avahi to see its own mDNS probe on the other interface and conflict with itself
  services.avahi.allowInterfaces = ["enp12s0"];

  # No battery on desktop — keep UPower running (wireplumber needs it for BT headset battery)
  # but disable all power management polling since there's no battery
  services.upower = {
    enable = true;
    ignoreLid = true;
    noPollBatteries = true;
  };

  # Cups resolves "localhost" to both 127.0.0.1 and ::1 — IPv6 disabled at kernel level so ::1 bind fails
  services.printing.listenAddresses = ["127.0.0.1:631"];
}
