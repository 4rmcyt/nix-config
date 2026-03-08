{
  config,
  inputs,
  lib,
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
    ../../../modules/networking/avahi
    ../../../modules/security
    ../../../modules/services

    # ../../../modules/base/distributed-builds
    ../../../modules/users/zeev
  ];

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
  # 6. Nix Configuration
  # =================================================================
  nix = {
    package = pkgs.lixPackageSets.latest.lix;
    channel.enable = false;
    registry.nixpkgs.flake = inputs.nixpkgs;
  };

  nix.settings = {
    cores = 4;
    max-jobs = 4;
    experimental-features = [
      "flakes"
      "nix-command"
      "auto-allocate-uids"
    ];
    auto-optimise-store = true;
    warn-dirty = false;
    keep-going = true;
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
    ];
    trusted-users = [
      "root"
      "@wheel"
      "nix-builder"
    ];
  };

  # =================================================================
  # 8. Environment
  # =================================================================
  environment.systemPackages = with pkgs; [
    lsof
    openssh
    sysstat

    # Network tools
    iproute2
    wireguard-tools

    # Build & deployment tools
    betula

    # Lix tooling
    lixPackageSets.latest.nixpkgs-review
    lixPackageSets.latest.nix-eval-jobs
    lixPackageSets.latest.nix-fast-build
    lixPackageSets.latest.colmena
    lixPackageSets.latest.nix-direnv
  ];

  environment.shells = with pkgs; [zsh];

  # =================================================================
  # 8. Home Manager
  # =================================================================
  # backupFileExtension is set in commonHomeManagerNixosConfig with unique timestamp

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
      allowedTCPPorts = [53 80 443];
      allowedUDPPorts = [53];
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
        27196 # Cloudflare Exporter
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
  my.headscale.enable = false;

  # =================================================================
  # 9.6. Media Cleaner
  # =================================================================
  services.media-cleaner = {
    enable = true;
    radarrApiKeyFile = config.sops.secrets.radarr_api_key.path;
    sonarrApiKeyFile = config.sops.secrets.sonarr_api_key.path;
  };

  services.ape-converter.enable = true;

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

    vscode-server.enable = false;

    # Split DNS for Tailscale: resolves *.example.com → homeserver's Tailscale IP
    # Binds to tailscale0 only; address is resolved dynamically at service start
    dnsmasq = {
      enable = true;
      settings = {
        interface = "tailscale0";
        bind-interfaces = true;
        no-resolv = true;
        no-hosts = true;
        conf-dir = "/run/dnsmasq";
      };
    };
  };

  # Write dnsmasq address config dynamically from Tailscale IP at service start
  systemd.services.dnsmasq = {
    after = ["tailscale-autoconnect.service"];
    wants = ["tailscale-autoconnect.service"];
    # RuntimeDirectory creates /run/dnsmasq before ExecStartPre runs (dnsmasq --test validates conf-dir)
    serviceConfig.RuntimeDirectory = "dnsmasq";
    preStart = ''
      TSIP=$(${pkgs.tailscale}/bin/tailscale ip -4 2>/dev/null || true)
      if [ -n "$TSIP" ]; then
        echo "address=/.${config.my.defaults.domain}/$TSIP" > /run/dnsmasq/address.conf
      fi
    '';
  };

  # =================================================================
  # 12. Users & Groups
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
