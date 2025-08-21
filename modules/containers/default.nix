{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = [
    pkgs.podman
    pkgs.podman-compose
    pkgs.podman-tui
  ];

  sops.secrets.containers_env = {
    sopsFile = ../../secrets/.env;
    owner = config.users.users.podman.name;
    group = config.users.groups.podman.name;
    mode = "0400";
    format = "dotenv";
  };

  users.users.podman = {
    isSystemUser = true;
    group = "podman";
    extraGroups = [
      "users"
      "podman"
    ];
  };
  users.groups.podman = {};

  users.extraGroups.podman.members = [
    "zeev"
    "uptime-kuma"
    "podman"
  ];

  networking.firewall.allowedTCPPorts = [
    # Podman
    2375 # Podman API (insecure, for local use only)
    2376 # Podman API (secure, for local use only)
    9948 # NextDNS Exporter
  ];
  networking.firewall.allowedUDPPorts = [
    # Podman
    2375 # Podman API (insecure, for local use only)
    2376 # Podman API (secure, for local use only)
  ];

  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = {
    # tl-sg-prometheus-exporter = {
    #   image = "ghcr.io/mad-ady/tl-sg-prometheus-exporter:main";
    #   autoStart = true;
    #   networks = [ "podman" ];
    #   ports = [ "127.0.0.1:8000:8000" ];
    #   volumes = [
    #     "${config.sops.secrets.tplinkExporterConfig.path}:/app/config.yaml:ro"
    #   ];
    # };
    nextdns-exporter = {
      image = "ghcr.io/raylas/nextdns-exporter";
      autoStart = true;
      networks = ["podman"];
      ports = ["127.0.0.1:9948:9948"];
      environmentFiles = [config.sops.secrets.containers_env.path];
    };
  };
}
