{ config, pkgs, lib, ... }:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
    hostName = "nextcloud.labhome.work";

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
        "nextcloud.labhome.work"
        "192.168.1.165"
        "homeserver.local"
      ];
      trusted_proxies = [ "127.0.0.1" ];
    };
  };

  sops.secrets.nextcloud_admin_password = {};

  networking.firewall.allowedTCPPorts = [ 8081 ];

  services.fail2ban-cloudflare = lib.mkIf config.services.fail2ban-cloudflare.enable {
    jails = {
      nextcloud = {
        serviceName = "phpfpm-nextcloud"; # Confirm this matches your PHP-FPM service
        failRegex = "^.*Login failed:.*(Remote IP: <HOST>).*$";
      };
    };
  };
}