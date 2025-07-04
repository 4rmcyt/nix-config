{ config, pkgs, lib, ... }:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
    
    hostName = "192.168.1.165";
    
    # Use local database with trust authentication
    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbname = "nextcloud";
      
      adminpassFile = config.sops.secrets.nextcloud_admin_password.path;
      adminuser = "admin";
    };
    
    # System settings
    settings = {
      overwriteprotocol = "http";
      trusted_domains = [ "192.168.1.165" "homeserver.local" ];
      trusted_proxies = [ "127.0.0.1" ];
    };
  };
  
  # SOPS secrets for Nextcloud
  sops.secrets.nextcloud_admin_password = {};
  services.nextcloud.webserver = "";
  # Open firewall for Nextcloud
  networking.firewall.allowedTCPPorts = [ 8081 ];
}
