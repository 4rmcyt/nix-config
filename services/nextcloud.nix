{ config, pkgs, lib, ... }:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud28;
    hostName = "nextcloud.example.com";
    
    # Let the module handle the nginx configuration
    nginx.enable = true;
    https = true; # Let the module handle SSL via ACME

    database.createLocally = false;
    config = {
      dbtype = "pgsql";
      dbhost = "localhost";
      dbuser = "nextcloud";
      dbname = "nextcloud";
      dbpassFile = config.sops.secrets.nextcloud_db_password.path;
      adminpassFile = config.sops.secrets.nextcloud_admin_password.path;
      adminuser = "admin";
    };
    settings = {
      overwriteprotocol = "https";
      trusted_domains = [ "nextcloud.example.com" ];
      trusted_proxies = [ "127.0.0.1" "::1" ];
    };
  };

  # This ensures the Nextcloud setup process waits for the database
  systemd.services.nextcloud-setup = {
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
  };
  
  # This ensures the main Nextcloud PHP service also waits for the database
  systemd.services.phpfpm-nextcloud = {
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
  };
}
