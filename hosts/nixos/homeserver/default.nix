{
  config,
  lib,
  pkgs,
  ...
}: {
  # =================================================================
  # Imports
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
    ../../../modules/monitoring/node-exporter-client.nix
    ../../../modules/networking
    ../../../modules/networking/ssh
    ../../../modules/networking/nut-server
    # ../../../modules/networking/avahi
    ../../../modules/security
    ../../../modules/services

    # ../../../modules/base/distributed-builds
    ../../../modules/backup
    ../../../modules/users/zeev
  ];

  # =================================================================
  # Secrets Management
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
  # Nix Configuration
  # =================================================================
  nix.settings = {
    cores = 4;
    max-jobs = 4;
    extra-system-features = ["big-parallel"];
    trusted-users = [
      "root"
      "@wheel"
      "nix-builder"
    ];
  };

  # =================================================================
  # Environment
  # =================================================================
  environment.systemPackages = with pkgs; [
    lsof
    openssh
    sysstat

    # Network tools
    iproute2
    iw
    wireguard-tools

    # DB tooling
    pgloader

    # Build & deployment tools
    betula

    # Lix tooling
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

  environment.shells = with pkgs; [zsh];

  # =================================================================
  # Networking
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
      loginServer = "https://hs.example.com";
      advertiseExitNode = true;
      advertiseRoutes = [
        (
          let
            parts = lib.splitString "." config.my.defaults.homeserver_lan;
          in "${lib.concatStringsSep "." (lib.take 3 parts)}.0/24"
        )
      ];
    };

    firewall.interfaces.tailscale0 = {
      allowedTCPPorts = [
        53
        80
        443
        3000 # Grafana
        3100 # Loki (gcp-relay alloy-client)
        8088 # CrowdSec LAPI (gcp-relay bouncer)
        9090 # Prometheus
        9091 # Database & infrastructure
        9100 # Node Exporter
        27196 # Cloudflare Exporter
      ];
      allowedUDPPorts = [53];
    };

    firewall.interfaces.enp0s31f6 = {
      allowedTCPPorts = [53];
      allowedUDPPorts = [53];
    };

    # Allow Podman containers to reach host services (Postgres, Redis)
    firewall.interfaces.podman0 = {
      allowedTCPPorts = [5432 6379];
    };

    firewall = {
      enable = true;

      # Logging
      logReversePathDrops = true;
      logRefusedConnections = false; # Avoid log spam

      allowedTCPPorts = [
        80 # HTTP (traefik)
        443 # HTTPS (traefik)
        2222 # SSH
        # 8000  # TP-Link Exporter
        # 11434 # Ollama API
        # 11435 # Ollama WebUI
      ];
      rejectPackets = true;
    };
  };

  # =================================================================
  # Traefik & Services Toggle
  # =================================================================
  my.backup = {
    enable = true;
    repository = "rclone:homeserver:restic/homeserver";
    passwordFile = config.sops.secrets.restic_password.path;
    rcloneConfigFile = config.sops.secrets.rclone_config.path;
    postgresqlDatabases = [
      "miniflux"
      "atuin"
      "bazarr"
      "radarr"
      "radarr-log"
      "sonarr"
      "sonarr-log"
      "prowlarr"
      "prowlarr-log"
      "dispatcharr"
    ];
    paths = [
      "/data/media/.state/nixarr/jellyfin"
      "/data/media/.state/nixarr/audiobookshelf"
      "/var/lib/kanidm"
    ];
  };

  sops.secrets.restic_password = {
    sopsFile = ../../../secrets/restic.yaml;
    mode = "0400";
  };
  sops.secrets.rclone_config = {
    sopsFile = ../../../secrets/restic.yaml;
    mode = "0400";
  };

  # Local restic backup to zbackup pool — independent of Google Drive/rclone
  services.restic.backups.local = {
    initialize = true;
    repository = "/backup/restic";
    passwordFile = config.sops.secrets.restic_password.path;
    paths = [
      "/run/backup-pg-dumps"
      "/data/media/.state/nixarr/jellyfin"
      "/data/media/.state/nixarr/audiobookshelf"
      "/var/lib/kanidm"
    ];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 3"
    ];
    timerConfig = {
      OnCalendar = "03:15";
      RandomizedDelaySec = "10min";
      Persistent = true;
    };
  };

  systemd.services.restic-backups-local = {
    after = ["backup-pg-dump.service" "zfs-import-zbackup.service"];
    requires = ["backup-pg-dump.service"];
  };

  my.hardening.enable = true;
  my.kanidmClient.enable = true;
  my.traefik.enable = true;
  my.headscale.enable = false;
  my.crowdsec.traefik.enable = true;
  my.crowdsec.nftables = {
    enable = true;
    secretsFile = ../../../secrets/crowdsec.yaml;
  };

  my.nodeExporter = {
    enable = true;
    openFirewall = false; # port already open in networking.firewall
    extraCollectors = ["pressure" "thermal_zone" "zfs"];
  };

  # =================================================================
  # Programs
  # =================================================================
  programs.gnupg.agent = {
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-tty;
  };

  # =================================================================
  # Services
  # =================================================================
  services = {
    # SSH configuration
    openssh = {
      enable = true;
      ports = [2222];
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
        AllowUsers = [config.my.defaults.user "nix-builder"];
      };
    };
  };

  my.unbound = {
    enable = true;
    interfaces = ["tailscale0" "enp0s31f6"];
    tailscaleIp = "100.64.0.3";
    gcpRelayIp = "203.0.113.1";
    nextdnsProfileId = "nextdns0";
  };

  # =================================================================
  # Users & Groups
  # =================================================================
  users = {
    users.git = {
      isSystemUser = true;
      description = "Git user";
      group = "git";
    };
    users.zeev = {
      shell = pkgs.zsh;
      extraGroups = lib.mkForce [
        "docker"
        "media"
        "networkmanager"
        "podman"
        "wheel"
        "zeev"
      ];
    };
    groups.git = {};
  };
}
