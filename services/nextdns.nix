{ config, pkgs, ... }:

{
  # NextDNS configuration
  services.nextdns = {
    enable = true;
    arguments = [
      "-config" "abcdef"  # Replace with your actual NextDNS config ID
      "-listen" "127.0.0.1:53"
      "-cache-size" "10MB"
      "-max-ttl" "5m"
      "-report-client-info"
      "-auto-activate"
    ];
  };

  # System DNS configuration
  networking.nameservers = lib.mkForce [ "127.0.0.1" ];
  
  # Disable conflicting DNS services
  services.resolved.enable = false;
}