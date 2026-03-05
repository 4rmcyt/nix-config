{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: {
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
    ../../../modules/GUI/chromium
    ../../../modules/GUI/flatpak/hyprland
    ../../../modules/GUI/virt-manager
    ../../../modules/xdg
    ../../../modules/services/tdarr-node
  ];

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
  # 5. Nix Configuration
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
      with pkgs; [
        zsh
        nushell
      ]
    );

    systemPackages = with pkgs; [
      # Lix Tooling
      lixPackageSets.latest.nixpkgs-review
      lixPackageSets.latest.nix-eval-jobs
      lixPackageSets.latest.nix-fast-build
      lixPackageSets.latest.colmena
      lixPackageSets.latest.nix-direnv
    ];
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
  # 11. Networking
  # =================================================================
  networking = {
    dnssec = {
      enable = true;
      profileId = "nextdns0";
    };
    enableIPv6 = false;
  };

  # =================================================================
  # 12. Programs
  # =================================================================
  programs = {
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
  };

  # =================================================================
  # 13. Services
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

    davfs2 = {
      enable = true;
      settings.sections."/data/zeev/Taildrive".gui_optimize = true;
    };

    openssh.enable = true;

    tailscale = {
      authKeyFile = config.sops.secrets.tailscale_auth_key.path;
      enable = true;
      useRoutingFeatures = "both";
      extraUpFlags = ["--accept-routes"];
    };
  };
  # =================================================================
  # 14. Users & Groups
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

  systemd.tmpfiles.rules = [
    "d /data/zeev/Taildrive 770 davfs2 users -"
  ];
}
