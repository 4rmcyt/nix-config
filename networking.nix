{ config, pkgs, lib, ... }:

{
  # Hostname
  networking.hostName = "homeserver";

  # Use NetworkManager
  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkForce false;

  # Firewall configuration
  networking.firewall = {
    enable = true;
    # Organize ports by service category
    allowedTCPPorts = [
      # Base services
      22    # SSH
      80    # HTTP (Caddy)
      443   # HTTPS (Caddy)

      # Authentication
      8080  # Keycloak

      # Media services
      8096  # Jellyfin
      8085  # Audiobookshelf

      # Content management
      8081  # Nextcloud
      8083  # Microbin
      8084  # Miniflux
      8888  # Paperless
      5232  # Radicale

      # System services
      8082  # Homepage dashboard
      8123  # Home Assistant
      51413 # Deluge
    ];

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
}
