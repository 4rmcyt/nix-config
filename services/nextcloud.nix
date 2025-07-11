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

  # Override the default vhost to listen only on localhost:8081
  services.nginx.virtualHosts."nextcloud.local" = {
    listen = [
      { addr = "127.0.0.1"; port = 8081; ssl = false; }
    ];
    # No need to set root/locations, Nextcloud module will do it
  };

  sops.secrets.nextcloud_admin_password = {};
  # REMOVED: Firewall ports (now handled centrally in networking.nix)
}