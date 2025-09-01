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
      8191 # FlareSolverr
      8265 # Tdarr Web UI
      8266 # Tdarr Server
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
        flaresolverr = {
          image = "ghcr.io/flaresolverr/flaresolverr:latest";
          autoStart = true;
          ports = [ "127.0.0.1:8191:8191/tcp" ];
          environment = {
            LOG_LEVEL = "info";
            TZ = "America/Edmonton";
          };
        };
        tdarr = {
         image = "ghcr.io/haveagitgat/tdarr";
         ports = [
          "4213:8265"
          "4214:8266"
        ];
        autoStart = true;
        environment = {
          PUID = "1000";
          PGID = "100";
          serverIP = "0.0.0.0";
          serverPort = "8266";
          webUIPort = "8265";
          internalNode = "true";
          inContainer = "true";
          ffmpegVersion = "7";
          nodeName = "drumknott";
          TZ = "America/Edmonton";
        };
        volumes = [
          "/data/media:/media"
          "/data/media/transcode-cache:/temp"
          "/var/lib/tdarr/configs:/app/configs"
          "/var/lib/tdarr/logs:/app/logs"
          "/var/lib/tdarr/data/server:/app/server"
          "/var/lib/tdarr/data/cache:/temp"
        ];
        extraOptions = [
          "--device=/dev/dri:/dev/dri"
        ];
       }
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

  systemd.tmpfiles.rules = [
    "d /data/media/transcode-cache 775 podman media -"
    "d /var/lib/tdarr/logs 775 podman podman -"
    "d /var/lib/tdarr/configs 775 podman podman -"
  ];
}
