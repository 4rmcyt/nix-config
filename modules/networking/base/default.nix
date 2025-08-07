{
  config,
  pkgs,
  lib,
  ...
}:

{
  networking = {
    hostName = "homeserver";
    hostId = "0b8d0f5a";
    networkmanager.enable = true;
    useDHCP = lib.mkForce true;
    enableIPv6 = false;

    firewall = {
      enable = true;

      # Logging
      logReversePathDrops = true;
      logRefusedConnections = false; # Avoid log spam

      extraRules = ''
        # Drop invalid packets
        -m conntrack --ctstate INVALID -j DROP

        # Block common TCP scan techniques
        -p tcp --tcp-flags ALL NONE -j DROP
        -p tcp --tcp-flags ALL ALL -j DROP

        # Rate limit new SSH connections
        -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set --name SSH
        -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP
      '';

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
        # 9948  # Nextdns Exporter
        27196 # Cloudflare Exporter
        3001 # Uptime Kuma

        # Database & Infrastructure
        5432 # PostgreSQL (if needed externally)
        9091

      ];

      rejectPackets = true;
      trustedInterfaces = [ "tailscale0" ];
    };
  };
}
