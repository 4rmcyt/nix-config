{
  config,
  pkgs,
  ...
}: {
  # =================================================================
  # 1. Imports
  # =================================================================
  imports = [
    # Hardware and system base
    ./hardware-configuration.nix
    ../../../modules/base
    ../../../modules/disko/homeserver
    ../../../modules/options

    # Infrastructure services
    ../../../modules/containers
    ../../../modules/database
    ../../../modules/monitoring
    ../../../modules/networking
    ../../../modules/networking/ssh
    ../../../modules/networking/nut-server
    ../../../modules/security
    ../../../modules/services
    # Distributed builds
    # ../../../modules/base/distributed-builds

    # User configuration
    ../../../modules/users/zeev

    # Disabled - uncomment when needed
    # ../../../modules/backup  # borgmatic config exists but not active
  ];

  # =================================================================
  # 2. System Configuration
  # =================================================================
  system.stateVersion = "25.05";

  nixpkgs.overlays = [
    (_final: prev: {
      # Fix intel-compute-runtime-legacy1 missing cstdint header
      # See: https://discourse.nixos.org/t/env-nix-cflags-compile-vs-cxxflags/39192
      intel-compute-runtime-legacy1 = prev.intel-compute-runtime-legacy1.overrideAttrs (oldAttrs: {
        NIX_CFLAGS_COMPILE = (oldAttrs.NIX_CFLAGS_COMPILE or "") + " -include cstdint";
      });
    })
    (_final: prev: {
      inherit
        (prev.lixPackageSets.latest)
        nixpkgs-review
        nix-eval-jobs
        nix-fast-build
        colmena
        ;
    })
  ];
  # =================================================================
  # 2.5. Distributed Builds Configuration
  # =================================================================
  # distributed-builds = {
  #   enable = true;
  #   role = "client";
  #   builders = [
  #     {
  #       hostName = config.my.network.hosts.desktop_lan;
  #       system = "x86_64-linux";
  #       maxJobs = 16;
  #       speedFactor = 2;
  #       supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "gccarch-skylake" "kvm"];
  #       publicHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEYURQfg2oU9NsUxV2ru/I/W5/mbUiGYplR1Fdepnole";
  #     }
  #   ];
  # };

  # =================================================================
  # 3. Secrets Management
  # =================================================================
  sops = {
    defaultSopsFormat = "yaml";
    secrets = {
      ssh_host_ed25519_key = {
        sopsFile = ../../../secrets/system.yaml;
        key = "ssh_host_ed25519_key";
        owner = config.users.users.root.name;
        group = config.users.groups.root.name;
        mode = "0600";
      };
      ssh_host_rsa_key = {
        sopsFile = ../../../secrets/system.yaml;
        key = "ssh_host_rsa_key";
        owner = config.users.users.root.name;
        group = config.users.groups.root.name;
        mode = "0600";
      };
      git_access_token = {
        sopsFile = ../../../secrets/common.yaml;
        key = "git_access_token";
      };
      nix_builder_private_key = {
        sopsFile = ../../../secrets/nix-builder-homeserver.yaml;
        key = "nix_builder_private_key";
        owner = "root";
        mode = "0600";
        path = "/root/.ssh/nix-builder";
      };
    };
  };

  # =================================================================
  # 4. Boot Configuration
  # =================================================================
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # =================================================================
  # 6. Nix Configuration
  # =================================================================
  # Note: Base nix settings are in modules/base/nix-settings.nix
  # Only host-specific overrides are defined here
  nix.package = pkgs.lixPackageSets.latest.lix;

  nix.settings = {
    cores = 4;
    max-jobs = 4;
    experimental-features = [
      "flakes"
      "nix-command"
      "lix-custom-sub-commands"
      "auto-allocate-uids"
    ];

    auto-optimise-store = false; # Disabled during builds (run manually: nix-store --optimise)
    warn-dirty = false;
    keep-going = true; # Continue building other derivations on failure

    # Network optimization for faster downloads
    max-substitution-jobs = 4; # Parallel downloads
    http-connections = 25; # More HTTP connections
    connect-timeout = 5; # Faster timeout

    # Store optimization for better performance
    keep-outputs = true; # Keep build dependencies for faster rebuilds
    keep-derivations = true; # Keep derivations for faster evaluation

    # Disk space management
    min-free = 5368709120; # 5GB - trigger GC when less than 5GB free
    max-free = 10737418240; # 10GB - stop GC when 10GB free

    # Build performance improvements
    builders-use-substitutes = true; # Allow builders to use substitutes
    require-sigs = true; # Security: require signatures

    # Evaluation performance
    eval-cache = true; # Cache evaluation results

    # Substituters and trusted keys are centralized in flake.nix

    extra-system-features = [
      "big-parallel"
    ];

    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  # =================================================================
  # 7. Environment
  # =================================================================
  environment.sessionVariables = {
    # GPG Agent for SSH (uses gpg-agent socket)
    SSH_AUTH_SOCK = "/run/user/$UID/gnupg/S.gpg-agent.ssh";
  };

  # Common packages now provided by modules/base/common-packages.nix
  # Only listing server-specific packages here
  environment.systemPackages = with pkgs; [
    # Core utilities (server-specific)
    lsof
    openssh

    # System monitoring & hardware
    apcupsd
    auto-cpufreq
    cpuid
    fwupd
    intel-gpu-tools
    libva-utils
    lm_sensors
    microcode-intel
    powertop
    prometheus-apcupsd-exporter
    smartmontools
    zfs
    clinfo

    # Network tools
    iproute2
    wireguard-tools

    # Build & deployment tools
    prometheus-cloudflare-exporter
    betula
  ];

  environment.shells = with pkgs; [zsh];

  # =================================================================
  # 8. Home Manager
  # =================================================================
  home-manager.backupFileExtension = "backup";

  # =================================================================
  # 9. Networking
  # =================================================================
  networking = {
    hostName = "homeserver";
    hostId = "0b8d0f5a";
    useDHCP = true;
    enableIPv6 = false;

    dnssec = {
      enable = true;
      profileId = "nextdns0";
    };

    tailscaleAuth = {
      enable = true;
      sopsFile = ../../../secrets/tailscale-homeserver.yaml;
      key = "tailscale_auth_key";
    };

    firewall = {
      enable = true;

      # Logging
      logReversePathDrops = true;
      logRefusedConnections = false; # Avoid log spam

      allowedTCPPorts = [
        # Base services
        22 # SSH
        80 # HTTP
        443 # HTTPS

        # 11434 # Ollama API
        # 11435 # Ollama WebUI

        # Monitoring (from monitoring.nix)
        3000 # Grafana
        9090 # Prometheus
        9100 # Node Exporter
        # 8000  # TP-Link Exporter
        # 9948  # Nextdns Exporter
        27196 # Cloudflare Exporter
        3001 # Uptime Kuma

        # Database & Infrastructure
        9091
      ];
      rejectPackets = true;
    };
  };

  # =================================================================
  # 9.5. Traefik Reverse Proxy
  # =================================================================
  my.traefik.enable = true;

  # =================================================================
  # 10. Programs
  # =================================================================
  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-tty;
    };

    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 10d --keep 3";
      flake = "/home/zeev/src/nix-config";
    };

    zsh.enable = true;
  };

  # =================================================================
  # 11. Services
  # =================================================================
  services = {
    # SSH configuration
    openssh = {
      enable = true;
      extraConfig = ''
        # Global Security Settings
        KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256
        Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
        MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
      '';
      hostKeys = [
        {
          type = "ed25519";
          inherit (config.sops.secrets.ssh_host_ed25519_key) path;
        }
        {
          type = "rsa";
          bits = 4096;
          inherit (config.sops.secrets.ssh_host_rsa_key) path;
        }
      ];
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Development services
    vscode-server.enable = true;
  };

  # =================================================================
  # 11.5. Systemd Services - Nix Daemon GitHub Token
  # =================================================================
  # Note: The git_access_token secret should contain: NIX_CONFIG="access-tokens = github.com=<token>"
  systemd.services.nix-daemon.serviceConfig.Environment = [
    "NIX_CONFIG=access-tokens = github.com=$(cat ${config.sops.secrets.git_access_token.path})"
  ];

  # =================================================================
  # 12. Users & Groups
  # =================================================================
  users = {
    users.git = {
      isSystemUser = true;
      description = "Git user";
      group = "git";
    };
    users.zeev.shell = pkgs.zsh;
    groups.git = {};
  };
}
