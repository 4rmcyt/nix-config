# { config, lib, ... }:

# {
#   networking = {
#     hostName = "homeserver";
    
#     interfaces.enp0s31f6 = {  # Replace with your actual interface name
#       ipv4.addresses = [ {
#         address = "192.168.1.165";
#         prefixLength = 24;
#       } ];
#     };
#     # Default gateway
#     defaultGateway = {
#       address = "192.168.1.254";
#       interface = "enp0s31f6";  # Must match interface name above
#     };

#     networkmanager.enable = false;
#     # Enable systemd-networkd for static configuration
#     useNetworkd = true;
    
#     firewall = {
#       enable = true;
#       trustedInterfaces = [ "tailscale0" ];
#       checkReversePath = "loose";
      
#       allowedTCPPorts = [
#         22    # SSH
#         80    # HTTP
#         443   # HTTPS
#         445  # SMB
#         139  # NetBIOS
#         3000  # Homepage Dashboard
#         5232  # Radicale
#         8080  # Keycloak (fixed from 8081)
#         8081  # Nextcloud (fixed from missing)
#         8082  # Paperless
#         8083  # Miniflux
#         8084  # File server
#         8085  # Audiobookshelf
#         8087  # Microbin Paste Server
#         8096  # Jellyfin HTTP
#         8112  # Deluge web
#         8123  # Home Assistant
#         8920  # Jellyfin HTTPS
#         8085  # Audiobookshelf
#       ];
      
#       allowedUDPPorts = [
#         1900  # Jellyfin DLNA
#         7359  # Jellyfin client discovery
#         41641 # Tailscale coordination
#         137  # NetBIOS Name Service
#         138  # NetBIOS Datagram Service
#       ];
#     };
#   };

#   boot.kernel.sysctl = {
#     "net.ipv4.ip_forward" = 1;
#     "net.ipv6.conf.all.forwarding" = 1;
#     "net.core.rmem_max" = 134217728;
#     "net.core.wmem_max" = 134217728;
#     "net.ipv4.tcp_rmem" = "4096 87380 134217728";
#     "net.ipv4.tcp_wmem" = "4096 65536 134217728";
#   };
# }

{ config, pkgs, lib, ... }:

{
  # Hostname
  networking.hostName = "homeserver";

  # Use DHCP for now (easier to get online)
  networking.useDHCP = true;
  networking.networkmanager.enable = true;

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];  # Just SSH for now
  };
}