{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../../modules/base
    ../../../modules/disko/homeserver
    ../../../modules/options

    ../../../modules/containers
    ../../../modules/database
    ../../../modules/monitoring
    ../../../modules/monitoring/node-exporter
    ../../../modules/networking
    ../../../modules/networking/ssh
    ../../../modules/networking/nut-server
    ../../../modules/security
    ../../../modules/services
    ../../../modules/backup

    ../../../modules/users/zeev
    ./hardening.nix
  ];

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

  nix.settings = {
    cores = 4;
    max-jobs = 4;
    extra-system-features = ["big-parallel"];
    # "root" + "@wheel" already come from parts/shared-nixos-settings.nix
    trusted-users = ["nix-builder"];
  };

  environment.systemPackages = with pkgs; [
    lsof
    sysstat

    iproute2
    iw
    wireguard-tools

    betula

    k9s
  ];

  environment.shells = with pkgs; [zsh];

  networking = {
    hostName = "homeserver";
    hostId = "0b8d0f5a";
    useDHCP = true;
    # Keep dhcpcd off container/k3s/VPN virtual links: IPv4LL on 20+ veths breaks multicast joins (HA SSDP ENOBUFS).
    dhcpcd.denyInterfaces = ["veth*" "flannel*" "cni*" "podman*" "wg-br"];
    enableIPv6 = true;

    # Server-side OIDC (Grafana, Miniflux) hits local Caddy, not MagicDNS → would hit Cloudflare Access if tailscaled is down.
    hosts."127.0.0.1" = ["idm.${config.my.defaults.domain}"];

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
        2222 # SSH
        config.my.network.ports.victorialogs-ingest # gcp-relay journal-upload (write-only Caddy front)
        config.my.network.ports.crowdsec-lapi # gcp-relay bouncer
        config.my.network.ports.prometheus
        config.my.network.ports.node-exporter
      ];
      allowedUDPPorts = [53];
    };

    # VictoriaLogs ingest front (write-only): from the LAN only desktop may reach it; tailnet side is gated by the headscale ACL.
    firewall.extraInputRules = ''
      iifname "enp0s31f6" ip saddr { ${config.my.network.hosts.desktop_lan}, ${config.my.network.hosts.desktop_wifi} } tcp dport ${toString config.my.network.ports.victorialogs-ingest} accept
      # Caddy everywhere except IPv6 on the LAN NIC: the router passes inbound IPv6 :443 to homeserver's global addresses.
      iifname != "enp0s31f6" tcp dport { 80, 443 } accept
      iifname != "enp0s31f6" udp dport 443 accept
      iifname "enp0s31f6" meta nfproto ipv4 tcp dport { 80, 443 } accept
      iifname "enp0s31f6" meta nfproto ipv4 udp dport 443 accept
      # SSH: IPv4 only on the LAN NIC (the router passed inbound IPv6 :2222 from the internet); tailnet via tailscale0.
      iifname "enp0s31f6" meta nfproto ipv4 tcp dport 2222 accept
      # DNS + Jellyfin (8920 HTTPS) for LAN/media-VLAN clients by IP; DLNA 1900 + Jellyfin discovery 7359. IPv4 only, same reason.
      iifname "enp0s31f6" meta nfproto ipv4 tcp dport { 53, ${toString config.my.network.ports.jellyfin}, 8920 } accept
      iifname "enp0s31f6" meta nfproto ipv4 udp dport { 53, 1900, 7359 } accept
    '';

    # Containers reach host services via host.containers.internal / host-gateway on podman0.
    firewall.interfaces.podman0.allowedTCPPorts = [
      config.my.network.ports.prowlarr # lazylibrarian Torznab
      config.my.network.ports.jellyfin # seerr
      config.my.network.ports.radarr # seerr
      config.my.network.ports.sonarr # seerr
    ];

    # 6443: ClusterIP DNATs to LAN IP not loopback (else CrashLoopBackOff/timeout). 10250: kubelet. 5432: Postgres.
    firewall.interfaces.cni0 = {
      allowedTCPPorts = [6443 10250 5432];
    };

    firewall = {
      enable = true;

      logReversePathDrops = true;
      logRefusedConnections = false; # Avoid log spam

      # 80/443 (Caddy) and 2222 (SSH) live in extraInputRules: IPv4-only on the LAN NIC.
      allowedTCPPorts = [
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
      "kombayn"
      "hass"
      "grafana"
    ];
    paths = [
      "/var/lib/kanidm"
      # Bazarr provider credentials/settings live in config.yaml, not its Postgres DB.
      "/data/media/.state/nixarr/bazarr/config"
      # job-kombayn's dedup index, resume/cover PDFs, geocode cache live in its StateDirectory.
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

  my.caddyHomeserver.enable = true;
  my.uaExit.enable = true;
  my.uaExitOvpn.enable = true;
  my.crowdsec.remoteCaddy = {
    enable = true;
    # remote_ip pins the sender: a LAN host can't inject fake gcp-relay Caddy lines to get IPs banned.
    query = ''{_HOSTNAME="gcp-relay", _SYSTEMD_UNIT="caddy.service"} remote_ip:="${config.my.network.hosts.gcp-relay_ts}"'';
  };
  my.crowdsec.nftables.enable = true;
  # gcp-relay's bouncer key, registered in this host's LAPI.
  sops.secrets.crowdsec_bouncer_key_gcp_relay = {
    sopsFile = ../../../secrets/crowdsec-gcp.yaml;
    key = "crowdsec_bouncer_key_nftables";
  };
  my.crowdsec.bouncers.gcp-relay-bouncer = config.sops.secrets.crowdsec_bouncer_key_gcp_relay.path;

  my.nodeExporter = {
    enable = true;
    openFirewall = false; # scraped locally; tailnet access via firewall.interfaces.tailscale0
    extraCollectors = ["pressure" "thermal_zone" "zfs"];
    textfileWriters = [config.my.defaults.user "kombayn"];
  };

  programs.gnupg.agent = {
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-tty;
  };

  services = {
    openssh = {
      enable = true;
      ports = [2222];
      # Default true opens 2222 on every interface/family; per-interface rules live in networking.firewall above.
      openFirewall = false;
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
        # PasswordAuthentication/PermitRootLogin set by ./hardening.nix — don't redeclare, dup priority fails eval.
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
      # Mirrors job-kombayn.env into a k8s Secret (gitops: k3s/job-kombayn/), not a replacement yet.
      enableK3sSecretSync = true;
      webBuild = pkgs.buildNpmPackage {
        pname = "job-kombayn-web";
        version = "0.1.0";
        src = "${inputs.jobshunting}/frontend";
        # importNpmLock reads hashes from package-lock.json — no npmDepsHash to update on bumps.
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
  };

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
