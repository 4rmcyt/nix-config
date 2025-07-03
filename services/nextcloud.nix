{ config, pkgs, ... }:

{
  sops.secrets.nextcloud_admin_password = { };
  sops.secrets.nextcloud_db_password = {
    owner = "nextcloud";
    group = "nextcloud";
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud30;
    hostName = "nextcloud.labhome.work";
    
    config = {
      adminuser = "admin";
      adminpassFile = config.sops.secrets.nextcloud_admin_password.path;
      
      # Use PostgreSQL database (configured in database.nix)
      dbtype = "pgsql";
      dbhost = "localhost";
      dbname = "nextcloud";
      dbuser = "nextcloud";
      dbpassFile = config.sops.secrets.nextcloud_db_password.path;
    };
    
    # Configure to work behind reverse proxy
    settings = {
      trusted_domains = [ "nextcloud.labhome.work" "127.0.0.1:8081" ];
      trusted_proxies = [ "127.0.0.1" ];
      overwriteprotocol = "https";
      overwritehost = "nextcloud.labhome.work";
      overwritewebroot = "/";
      
      "default_phone_region" = "US";
      "maintenance_window_start" = 1;
    };
    
    # Configure PHP settings
    phpOptions = {
      "opcache.revalidate_freq" = "0";
      "opcache.interned_strings_buffer" = "16";
      "opcache.max_accelerated_files" = "10000";
      "opcache.memory_consumption" = "128";
      "opcache.save_comments" = "1";
      "opcache.validate_timestamps" = "1";
    };
  };

  # Configure nginx to listen on port 8081 (required by Nextcloud module)
  services.nginx = {
    enable = true;
    virtualHosts."nextcloud.labhome.work" = {
      listen = [{ addr = "127.0.0.1"; port = 8081; }];
    };
  };
  
  # Open firewall port for local access
  networking.firewall.allowedTCPPorts = [ 8081 ];
}