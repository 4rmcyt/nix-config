{
  config,
  pkgs,
  lib,
  ...
}:

{
  networking = {
    hostName = "homeserver";
    networkmanager.enable = true;
    useDHCP = lib.mkForce true;
    enableIPv6 = false;

    firewall = {
      enable = true;

      allowedTCPPorts = [
        # Base services
        22 # SSH
        80 # HTTP
        443 # HTTPS

        # Authentication
        9000 # Authentik
        8080 # Authentik Outpost Proxy

        # LDAP
        6360 # LDAP (LDAP server)
        3890 # LDAP (LDAP server, non-SSL)
        17170 # LDAP (LDAP server, non-SSL, for testing)

        # Media services
        8096 # Jellyfin
        8920 # Jellyfin HTTPS
        9292 # Audiobookshelf
        58403 # VPN test service
        63998 # Transmission peer
        9091 # Transmission web UI
        8989 # Sonarr
        7878 # Radarr
        9696 # Prowlarr
        6767 # Bazarr
        5055 # Jellyseerr
        8686 # Lidarr
        2468 # Cross-seed

        # Content management
        8084 # Microbin
        8083 # Calibre-Web

        8086 # Miniflux
        8888 # Paperless
        6379 # Redis (for Paperless)
        5232 # Radicale
        5000 # Kavita
        # 11434 # Ollama API
        # 11435 # Ollama WebUI

        # System services
        8082 # Homepage dashboard
        8123 # Home Assistant
        8222 # Vaultwarden (Bitwarden)
        12522 # Linkwarden

        # Monitoring (from monitoring.nix)
        3000 # Grafana
        9090 # Prometheus
        9100 # Node Exporter
        # 8000  # TP-Link Exporter
        # 9948  # Nextdns Exporter
        27196 # Cloudflare Exporter
        3001 # Uptime Kuma

        # Database & Infrastructure
        1883 # Mosquitto MQTT
        5432 # PostgreSQL (if needed externally)

      ];

      # UDP ports for specific services
      allowedUDPPorts = [
        1900 # Jellyfin DLNA
        7359 # Jellyfin discovery
      ];

      trustedInterfaces = [ "tailscale0" ];

      logReversePathDrops = true;
    };
  };

  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
}
