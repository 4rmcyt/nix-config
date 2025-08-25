{ ... }:
{
  imports = [
    ./acme
    ./cloudflared
    ./nginx
    ./tailscale
  ];
  networking = {
    hostName = "homeserver";
    hostId = "0b8d0f5a";
    networkmanager.enable = true;
    useNetworkd = false;
    enableIPv6 = false;

    firewall = {
      enable = true;
      logReversePathDrops = true;
      logRefusedConnections = false;
      rejectPackets = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedTCPPorts = [
        22 # SSH
        80 # HTTP
        443 # HTTPS
        3000 # Grafana
        9090 # Prometheus
        9100 # Node Exporter
        27196 # Cloudflare Exporter
        3001 # Uptime Kuma
        5432 # PostgreSQL
        9091
      ];
    };
  };
}
