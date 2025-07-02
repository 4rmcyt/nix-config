{ config, pkgs, ... }:

{
  sops.secrets.tailscale_auth_key = { };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";  # Enable subnet routing and exit node
    
    # Don't interfere with existing firewall rules
    interfaceName = "tailscale0";
    
    # Use systemd-resolved for DNS
    extraUpFlags = [
      "--accept-dns=false"  # Don't override DNS settings
      "--accept-routes"     # Accept subnet routes
      "--shields-up=false"  # Allow incoming connections
    ];
  };

  # Tailscale-specific firewall rules
  networking.firewall = {
    # Allow Tailscale traffic
    trustedInterfaces = [ "tailscale0" ];
    
    # Allow UDP for Tailscale coordination
    allowedUDPPorts = [ 41641 ];
    
    # Don't check IP forwarding - Tailscale handles this
    checkReversePath = "loose";
  };

  # Enable IP forwarding for subnet routing
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Tailscale authentication service
  systemd.services.tailscale-auth = {
    description = "Tailscale authentication";
    after = [ "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.tailscale}/bin/tailscale up --authkey file:${config.sops.secrets.tailscale_auth_key.path} --accept-routes --shields-up=false";
    };
  };
}