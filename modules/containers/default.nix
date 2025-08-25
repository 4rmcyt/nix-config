{
  config,
  pkgs,
  ...
}:
{
  environment.systemPackages = [
    pkgs.podman
    pkgs.podman-compose
    pkgs.podman-tui
    pkgs.docker-compose
  ];

  sops.secrets.containers_env = {
    sopsFile = ../../secrets/.env;
    owner = config.users.users.podman.name;
    group = config.users.groups.podman.name;
    mode = "0400";
    format = "dotenv";
  };

  users = {
    users.podman = {
      isSystemUser = true;
      group = "podman";
      extraGroups = [
        "users"
        "podman"
      ];
    };
    groups.podman = { };
    extraGroups.podman.members = [
      "zeev"
      "uptime-kuma"
      "podman"
    ];
  };

  networking.firewall = {
    allowedTCPPorts = [
      # Podman
      2375 # Podman API (insecure, for local use only)
      2376 # Podman API (secure, for local use only)
      9948 # NextDNS Exporter
      5299 # Lazylibrarian
    ];
    allowedUDPPorts = [
      # Podman
      2375 # Podman API (insecure, for local use only)
      2376 # Podman API (secure, for local use only)
    ];
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers = {
      backend = "podman";
      containers = {
        lazylibrarian = {
          image = "lscr.io/linuxserver/lazylibrarian:latest";
          autoStart = true;
          networks = [ "podman" ];
          ports = [ "127.0.0.1:5299:5299/tcp" ];
          environment = {
            DOCKER_MODS = "linuxserver/mods:universal-calibre|linuxserver/mods:lazylibrarian-ffmpeg";
            PUID = "100000";
            PGID = "65536";
            TZ = "America/Edmonton";
          };
          volumes = [
            "/data/media/.state/lazylibrarian/data:/config:rw"
            "/data/Downloads:/downloads:rw"
            "/data/media/books:/books:rw"
          ];
        };
        nextdns-exporter = {
          image = "ghcr.io/raylas/nextdns-exporter";
          autoStart = true;
          networks = [ "podman" ];
          ports = [ "127.0.0.1:9948:9948/tcp" ];
          environmentFiles = [ config.sops.secrets.containers_env.path ];
        };
      };
    };
  };
}
