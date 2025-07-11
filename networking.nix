
{ config, pkgs, lib, ... }:

{
  # CLEANED: Single networking configuration block
  networking = {
    hostName = "homeserver";
    networkmanager.enable = true;
    useDHCP = lib.mkForce false;
    enableIPv6 = false;
    
    # Firewall configuration
    firewall = {
      enable = true;
      
      # RESTORED: Comprehensive port list - well organized and documented
      allowedTCPPorts = [
        # Base services
        22    # SSH
        80    # HTTP (Caddy)
        443   # HTTPS (Caddy)
        2019  # Caddy Admin

        # Authentication
        8080  # Keycloak

        # Media services
        8096  # Jellyfin
        8920  # Jellyfin HTTPS
        8085  # Audiobookshelf

        # Content management
        8081  # Nextcloud
        8083  # Microbin
        8086  # Miniflux
        8888  # Paperless
        5232  # Radicale
        5000  # Kavita
        9091 # Transmission web UI

        # System services
        8082  # Homepage dashboard
        8123  # Home Assistant
        8112  # Deluge web UI
        51413 # Deluge daemon

        # Monitoring (from monitoring.nix)
        3000  # Grafana
        9090  # Prometheus
        9100  # Node Exporter

        # Database & Infrastructure
        1883  # Mosquitto MQTT
        5432  # PostgreSQL (if needed externally)
      ];

      # UDP ports for specific services
      allowedUDPPorts = [
        1900  # Jellyfin DLNA
        7359  # Jellyfin discovery
      ];
      
      # Allow local network access
      trustedInterfaces = [ "tailscale0" ];
      
      # Log dropped packets for better security analysis
      logReversePathDrops = true;

      # Use more specific rules for certain services
      extraCommands = ''
        # Allow established connections
        iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

        # Rate limiting for SSH to prevent brute force
        iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
        iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
      '';
    };
  };

  # CENTRALIZED: Kernel parameters for networking
  boot.kernel.sysctl = {
    # Enable IP forwarding for VPN services (Tailscale + Deluge VPN)
    "net.ipv6.conf.all.forwarding" = 1;
    
    # Additional network optimizations
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
}