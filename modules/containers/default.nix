{
  config,
  pkgs,
  ...
}:
{
  sops.secrets = {
    linkwarden_db_password = {
      sopsFile = ../../secrets/postgresql.yaml;
      key = "linkwarden_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
    containers_env = {
      sopsFile = ../../secrets/containers.yaml;
      owner = config.users.users.podman.name;
      group = config.users.groups.podman.name;
      mode = "0400";
      format = "dotenv";
    };
  };

  environment.systemPackages = [
    pkgs.podman
    pkgs.podman-compose
    pkgs.podman-tui
    pkgs.docker-compose
  ];


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
      8191 # FlareSolverr
      8265 # Tdarr Web UI
      8266 # Tdarr Server
      8267 # Tdarr Node
      3004 # Linkwarden
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
        nextdns-exporter = {
          image = "ghcr.io/raylas/nextdns-exporter";
          autoStart = true;
          networks = [ "podman" ];
          ports = [ "127.0.0.1:9948:9948/tcp" ];
          environmentFiles = [ config.sops.secrets.containers_env.path ];
        };
        linkwarden = {
          image = "ghcr.io/linkwarden/linkwarden";
          autoStart = true;
          ports = [ "127.0.0.1:3004:3000/tcp" ];
          environment = {
            TZ = "America/Edmonton";
            DATABASE_URL = "postgresql://linkwarden:${config.sops.secrets.linkwarden_db_password.path}@/run/postgresql/linkwarden?sslmode=disable";
            NEXTAUTH_SECRET = config.sops.secrets.containers_env.LINKWARDEN_NEXTAUTH_SECRET;
            NEXTAUTH_URL = "http://localhost:3004/api/v1/auth";
            CUSTOM_OPENAI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta";
            OPENAI_MODEL = "gemini-2.0-flash";
            OPENAI_API_KEY = "AIzaSyDpUZqecAdTeDxE3tEASd9VsEEB58_zYO4";
            NEXT_PUBLIC_DISABLE_REGISTRATION = "true";
          };
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/tdarr/data/cache 775 root media -"
    "d /var/lib/tdarr/data/server 775 root media -"
    "d /var/lib/tdarr/logs 775 root media -"
    "d /var/lib/tdarr/configs 775 root media -"
  ];
}
