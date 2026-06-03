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
        # 22 is handled by Cowrie (Podman DNAT in nat/prerouting, before NIXOS-FW filter)
        # 23 is handled by Cowrie Telnet (same Podman DNAT mechanism)
        80 # HTTP
        443 # HTTPS
        2222 # Real SSH (moved from 22; Cowrie honeypot takes port 22)
        3000 # Grafana
        9090 # Prometheus
        9091 # Database & infrastructure
        9100 # Node Exporter
        27196 # Cloudflare Exporter
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
  my.traefik.enable = true;
  my.headscale.enable = false;
  my.crowdsec.traefik.enable = true;

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
      ports = [2222]; # Moved from 22; Cowrie honeypot listens on port 22
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

    vscode-server.enable = false;
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
        "ollama"
        "networkmanager"
        "podman"
        "wheel"
        "zeev"
      ];
    };
    groups.git = {};
  };
}
