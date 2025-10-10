{
  config,
  pkgs,
  ...
}:
{
  sops.secrets = {
    containers_env = {
      sopsFile = ../../secrets/.env;
      owner = config.users.users.podman.name;
      group = config.users.groups.podman.name;
      mode = "0400";
      format = "dotenv";
    };
    linkwarden_env = {
      sopsFile = ../../secrets/linkwarden.env;
      owner = config.users.users.podman.name;
      group = config.users.groups.podman.name;
      mode = "0400";
      format = "dotenv";
    };
  };

  environment.systemPackages = [
    pkgs.docker-compose
    pkgs.podman
    pkgs.podman-compose
    pkgs.podman-tui
  ];

  users = {
    users.podman = {
      isSystemUser = true;
      group = "podman";
      extraGroups = [
        "podman"
        "users"
      ];
    };
    groups.podman = { };
    extraGroups.podman.members = [
      "podman"
      "uptime-kuma"
      "zeev"
    ];
  };

  networking.firewall = {
    allowedTCPPorts = [
      # Podman API
      2375 # Podman API (insecure, for local use only)
      2376 # Podman API (secure, for local use only)
      # Container services
      3004 # Linkwarden
      8191 # FlareSolverr
      8265 # Tdarr Web UI
      8266 # Tdarr Server
      8267 # Tdarr Node
      9948 # NextDNS Exporter
    ];
    allowedUDPPorts = [
      # Podman API
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
        linkwarden = {
          image = "ghcr.io/linkwarden/linkwarden";
          autoStart = true;
          ports = [ "127.0.0.1:3000:3004/tcp" ];
          environment = {
            TZ = "America/Edmonton";
            CUSTOM_OPENAI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta";
            OPENAI_MODEL = "gemini-2.0-flash";
            OPENAI_API_KEY = "REDACTED";
            # NEXT_PUBLIC_DISABLE_REGISTRATION = "true";
          };
          environmentFiles = [ config.sops.secrets.linkwarden_env.path ];
          volumes = [ "/var/lib/linkwarden:/data/data" ];
          extraOptions = [
            "--network=host"
          ];
        };
        nextdns-exporter = {
          image = "ghcr.io/raylas/nextdns-exporter";
          autoStart = true;
          networks = [ "podman" ];
          ports = [ "127.0.0.1:9948:9948/tcp" ];
          environmentFiles = [ config.sops.secrets.containers_env.path ];
        };
        tdarr = {
          image = "ghcr.io/haveagitgat/tdarr:latest";
          ports = [
            "8265:8265"
            "8266:8266"
            "8267:8267"
          ];
          autoStart = true;
          environment = {
            serverIP = "0.0.0.0";
            serverPort = "8266";
            webUIPort = "8265";
            internalNode = "true";
            inContainer = "true";
            ffmpegVersion = "7";
            nodeName = "homeserver";
            TZ = "America/Edmonton";
          };
          volumes = [
            "/data/media:/media"
            "/var/lib/tdarr/configs:/app/configs"
            "/var/lib/tdarr/logs:/app/logs"
            "/var/lib/tdarr/data/server:/app/server"
            "/var/lib/tdarr/data/cache:/temp"
          ];
          extraOptions = [
            "--device=/dev/dri:/dev/dri"
          ];
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/linkwarden 775 root media -"
    "d /var/lib/tdarr/configs 775 root media -"
    "d /var/lib/tdarr/data/cache 775 root media -"
    "d /var/lib/tdarr/data/server 775 root media -"
    "d /var/lib/tdarr/logs 775 root media -"
  ];
}