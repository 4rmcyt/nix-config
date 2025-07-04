{ config, pkgs, lib, ... }:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
    hostName = "nextcloud.example.com";

    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbname = "nextcloud";
      adminuser = "admin";
      adminpassFile = config.sops.secrets.nextcloud_admin_password.path;
    };

    settings = {
      overwriteprotocol = "https"; # Use "https" if behind Cloudflare Tunnel
      trusted_domains = [
        "nextcloud.example.com"
        "192.168.1.165"
        "homeserver.local"
      ];
      trusted_proxies = [ "127.0.0.1" ];
    };
  };

  sops.secrets.nextcloud_admin_password = {};

  networking.firewall.allowedTCPPorts = [ 8081 ];

}