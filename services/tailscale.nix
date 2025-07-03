{ config, pkgs, lib, ... }:

{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    
    # Enable as exit node
    extraUpFlags = [
      "--advertise-exit-node"
      "--advertise-routes=192.168.1.0/24"
    ];
  };
  
  # SOPS secret for Tailscale auth key
  sops.secrets.tailscale_auth_key = {};
  
  # Open firewall for Tailscale
  networking.firewall = {
    allowedUDPPorts = [ 41641 ];
    trustedInterfaces = [ "tailscale0" ];
  };
  
  # Enable IP forwarding for exit node
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
}
