{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
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
    ../../../modules/security
    ../../../modules/services
    ../../../modules/backup

    # not in use: ../../../modules/networking/avahi
    ../../../modules/users/zeev
  ];

  # Secrets Management
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
      job_kombayn_env = {
        sopsFile = ../../../secrets/job-kombayn.env;
        format = "dotenv";
        key = "job_kombayn_env";
        owner = "kombayn";
        mode = "0400";
      };
    };
  };

  # Nix Configuration
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

  # Environment
  environment.systemPackages = with pkgs; [
    lsof
    openssh
    sysstat

    # Network tools
    iproute2
    iw
    wireguard-tools

    # Build & deployment tools
    betula
  ];

  environment.shells = with pkgs; [zsh];

  # Networking
  networking = {
    hostName = "homeserver";
    hostId = "0b8d0f5a";
    useDHCP = true;
    enableIPv6 = false;

    dnssec = {
      enable = true;
      profileId = config.my.defaults.nextdnsProfileId;
    };

    tailscaleAuth = {
      enable = true;
      sopsFile = ../../../secrets/tailscale-homeserver.yaml;
      loginServer = "https://hs.${config.my.defaults.domain}";
      networkInterface = "enp0s31f6";
      advertiseExitNode = true;
      advertiseRoutes = [
        (
          let
            parts = lib.splitString "." config.my.network.hosts.homeserver_lan;
          in "${lib.concatStringsSep "." (lib.take 3 parts)}.0/24"
        )
      ];
    };

    firewall.interfaces.tailscale0 = {
      allowedTCPPorts = [
        53
        80
        443
        config.my.network.ports.grafana
        config.my.network.ports.loki # gcp-relay alloy-client
        8088 # CrowdSec LAPI (gcp-relay bouncer)
        config.my.network.ports.prometheus
        9091 # Database & infrastructure
        config.my.network.ports.node-exporter
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
      "kombayn"
      "hass"
      "grafana"
    ];
    paths = [
      "/var/lib/kanidm"
      # Bazarr provider credentials, hashed passwords and settings live in
      # config.yaml, not in its Postgres DB -- back it up separately.
      "/data/media/.state/nixarr/bazarr/config"
      # job-kombayn's dedup index, generated resume/cover PDFs and geocode
      # cache live in its StateDirectory, not in the kombayn Postgres DB.
      "/var/lib/job-kombayn"
      # Obsidian LiveSync vault — CouchDB is the only copy of live sync history.
      "/var/lib/couchdb"
      # CalDAV/CardDAV collections (calendars, contacts).
      "/var/lib/radicale/collections"
      # Comic/manga library metadata (H2 database) and thumbnails.
      "/var/lib/komga"
      # komf's cache/config.
      "/var/lib/komf"
      # Paste/file-share uploads.
      "/var/lib/microbin"
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
      "/var/backup/pg-dumps"
      "/data/media/.state/nixarr/audiobookshelf"
      "/data/media/.state/nixarr/bazarr"
      "/data/media/.state/nixarr/kapowarr"
      "/data/media/.state/nixarr/lazylibrarian"
      "/data/media/.state/nixarr/lidarr"
      "/data/media/.state/nixarr/prowlarr"
      "/data/media/.state/nixarr/qbittorrent"
      "/data/media/.state/nixarr/radarr"
      "/data/media/.state/nixarr/recyclarr"
      "/data/media/.state/nixarr/seerr"
      "/data/media/.state/nixarr/sonarr"
      "/var/lib/hass"
      "/var/lib/kanidm"
      "/var/lib/couchdb"
      "/var/lib/radicale/collections"
      "/var/lib/komga"
      "/var/lib/komf"
      "/var/lib/microbin"
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
    after = ["zfs-import-zbackup.service"];
  };

  my.hardening.enable = true;
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
    textfileWriters = [config.my.defaults.user "kombayn"];
  };

  # Programs
  programs.gnupg.agent = {
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-tty;
  };

  # Services
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
    jobKombayn = {
      enable = true;
      src = inputs.jobshunting;
      notify = true;
      onCalendar = "*-*-* 0/3:00:00"; # every 3 hours instead of hourly
      environmentFile = config.sops.secrets.job_kombayn_env.path;
      enableBot = true; # Applied/Skip inline buttons on vacancy cards
      enableApi = true; # HTTP API for the web frontend (jobko.<domain>/api)
      enableWeb = true; # static SPA (jobko.<domain>)
      webBuild = pkgs.buildNpmPackage {
        pname = "job-kombayn-web";
        version = "0.1.0";
        src = "${inputs.jobshunting}/frontend";
        # importNpmLock reads the per-package integrity hashes already in
        # package-lock.json instead of a single pinned npmDepsHash, so a
        # frontend dependency bump (package-lock.json change) never needs a
        # matching hash update here.
        npmDeps = pkgs.importNpmLock {npmRoot = "${inputs.jobshunting}/frontend";};
        npmConfigHook = pkgs.importNpmLock.npmConfigHook;
        installPhase = ''
          mkdir -p $out
          cp -r dist $out/dist
        '';
      };
    };
  };

  my.unbound = {
    enable = true;
    interfaces = ["tailscale0" "enp0s31f6"];
    tailscaleIp = config.my.network.hosts.homeserver_ts;
    gcpRelayIp = config.my.defaults.gcpRelayIp;
    nextdnsProfileId = config.my.defaults.nextdnsProfileId;
  };

  # Users & Groups
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
