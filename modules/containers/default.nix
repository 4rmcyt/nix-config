{
  config,
  pkgs,
  ...
}: {
  sops.secrets = {
    containers_env = {
      format = "dotenv";
      group = config.users.groups.podman.name;
      mode = "0400";
      owner = config.users.users.podman.name;
      sopsFile = ../../secrets/.env;
    };
  };

  environment.systemPackages = [
    pkgs.docker-compose
    pkgs.podman
    pkgs.podman-compose
    pkgs.podman-tui
  ];

  users = {
    extraGroups.podman.members = [
      config.my.defaults.user
      "podman"
      "uptime-kuma"
    ];
    groups.podman = {};
    users.podman = {
      extraGroups = [
        "podman"
        "users"
      ];
      group = "podman";
      isSystemUser = true;
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      # Podman API - Uncomment only if you need remote API access
      # 2375 # Podman API (insecure, for local use only - NOT RECOMMENDED)
      # 2376 # Podman API (secure with TLS, for local use only)
      # Container services
      8191 # FlareSolverr
      8265 # Tdarr Web UI
      8266 # Tdarr Server
      8267 # Tdarr Node
      9948 # NextDNS Exporter
    ];
    allowedUDPPorts = [
      # Podman API - Uncomment only if you need remote API access
      # 2375 # Podman API (insecure, for local use only - NOT RECOMMENDED)
      # 2376 # Podman API (secure with TLS, for local use only)
    ];
  };

  virtualisation = {
    oci-containers = {
      backend = "podman";
      containers = {
        flaresolverr = {
          autoStart = true;
          environment = {
            LOG_LEVEL = "info";
            TZ = "America/Edmonton";
          };
          image = "ghcr.io/flaresolverr/flaresolverr:latest";
          ports = ["127.0.0.1:8191:8191/tcp"];
        };

        nextdns-exporter = {
          autoStart = true;
          environmentFiles = [config.sops.secrets.containers_env.path];
          image = "ghcr.io/raylas/nextdns-exporter";
          networks = ["podman"];
          ports = ["127.0.0.1:9948:9948/tcp"];
        };
        # tdarr = {
        #   autoStart = true;
        #   environment = {
        #     TZ = "America/Edmonton";
        #     ffmpegVersion = "7";
        #     inContainer = "true";
        #     internalNode = "true";
        #     nodeName = "homeserver";
        #     serverIP = "0.0.0.0";
        #     serverPort = "8266";
        #     webUIPort = "8265";
        #   };
        #   extraOptions = [
        #     "--device=/dev/dri:/dev/dri"
        #   ];
        #   image = "ghcr.io/haveagitgat/tdarr:latest";
        #   ports = [
        #     "8265:8265"
        #     "8266:8266"
        #     "8267:8267"
        #   ];
        #   volumes = [
        #     "/data/media:/media"
        #     "/var/lib/tdarr/configs:/app/configs"
        #     "/var/lib/tdarr/data/cache:/temp"
        #     "/var/lib/tdarr/data/server:/app/server"
        #     "/var/lib/tdarr/logs:/app/logs"
        #   ];
        # };
      };
    };
    podman = {
      defaultNetwork.settings = {
        dns_enabled = true;
        gateway = "10.88.0.1";
        subnet = "10.88.0.0/16";
      };
      dockerCompat = true;
      enable = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/tdarr/configs 775 root media -"
    "d /var/lib/tdarr/data/cache 775 root media -"
    "d /var/lib/tdarr/data/server 775 root media -"
    "d /var/lib/tdarr/logs 775 root media -"
  ];
}
