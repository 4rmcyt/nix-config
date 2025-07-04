{ config, pkgs, lib, ... }:
{
  sops.secrets.nextdns_config_id = { };

  # NextDNS configuration
  services.nextdns = {
    enable = true;
    settings = {
      profile = "nextdns0";
    };
    # profile = "nextdns0";
    # arguments = [
    #   "-config" "$(cat ${config.sops.secrets.nextdns_config_id.path})"
    #   "-listen" "127.0.0.1:53"
    #   "-cache-size" "10MB"
    #   "-max-ttl" "5m"
    #   "-report-client-info"
    #   "-auto-activate"
    # ];
  };

  # System DNS configuration
  networking.nameservers = lib.mkForce [ "127.0.0.1" ];
  
  # Disable conflicting DNS services
  services.resolved.enable = false;
}