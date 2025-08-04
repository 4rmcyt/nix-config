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

      # UDP ports for specific services

      trustedInterfaces = [ "tailscale0" ];

      logReversePathDrops = true;
    };
  };  
}
