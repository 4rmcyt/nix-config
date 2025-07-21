{ config, pkgs, lib, ... }:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
    hostName = "nextcloud.local";
    database.createLocally = false;
    config = {
      dbtype = "pgsql";
      dbhost = "localhost";       
      dbuser = "nextcloud";
      dbname = "nextcloud";
      dbpassFile = config.sops.secrets.nextcloud_db_password.path;
      adminpassFile = config.sops.secrets.nextcloud_admin_password;
      adminuser = "admin";
    };
    settings = {
      overwriteprotocol = "http";
      trusted_domains = [ "nextcloud.local" "192.168.1.165" "nextcloud.example.com" ];
      trusted_proxies = [ "127.0.0.1" ];
    };
  };

  systemd.services.nextcloud-setup = {
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
  };
  
  # This ensures the main Nextcloud PHP service also waits for the database
  systemd.services.phpfpm-nextcloud = {
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
  };

  services.nginx.enable = true;
  

  services.nginx.virtualHosts."nextcloud.local" = {
    listen = [
      { addr = "127.0.0.1"; port = 8081; ssl = false; }
    ];
  };

} 