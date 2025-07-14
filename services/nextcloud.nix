{ config, pkgs, lib, ... }:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
    hostName = "nextcloud.local"; # or your public domain
    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbname = "nextcloud";
      dbpassFile = config.sops.secrets.nextcloud_db_password.path;      
      adminpassFile = config.sops.secrets.nextcloud_admin_password.path;
      adminuser = "admin";
    };
    settings = {
      overwriteprotocol = "http";
      trusted_domains = [ "nextcloud.local" "192.168.1.165" "nextcloud.labhome.work" ];
      trusted_proxies = [ "127.0.0.1" ];
    };
  };

  services.nginx.enable = true;

  services.nginx.virtualHosts."nextcloud.local" = {
    listen = [
      { addr = "127.0.0.1"; port = 8081; ssl = false; }
    ];
    # No need to set root/locations, Nextcloud module will do it
  };

}