{ config, pkgs, ... }:

{
  # Enable Tailscale
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    authKeyFile = config.sops.secrets.tailscale_auth_key.path;
    extraUpFlags = [
      "--accept-dns=false"  # Use NextDNS instead of Tailscale DNS
      "--accept-routes"
      "--ssh"
      "--advertise-tags=tag:homeserver"
    ];
  };

  # Allow Tailscale through firewall
  networking.firewall = {
    allowedUDPPorts = [ config.services.tailscale.port ];
    trustedInterfaces = [ "tailscale0" ];
  };

  # Tailscale secrets
  sops.secrets.tailscale_auth_key = { };
  sops.secrets.tailscale_ip = { };

  # Enable IP forwarding for subnet routing
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Configure static Tailscale IP (optional, for documentation)
  # The actual IP is assigned by Tailscale control plane
  # but we store it in secrets for reference
}