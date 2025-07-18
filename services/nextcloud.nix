{ config, pkgs, lib, ... }:

{
  # 1. Nextcloud Service Configuration
  services.nextcloud = {
    enable = true;
    hostName = "nextcloud.labhome.work";
    package = pkgs.nextcloud28;

    # Use php-fpm for better performance
    phpPackage = pkgs.php82;
    extraAppsEnable = true;
    extraApps = with pkgs.nextcloud28Apps; [
      calendar
      contacts
      deck
      notes
      tasks
      news
      passwords
    ];

    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbname = "nextcloud";
      # This now correctly points to the 'database_passwords' group
      dbpassFile = config.sops.secrets.database_passwords.path;
      # This now correctly points to the 'nextcloud_secrets' group
      adminpassFile = config.sops.secrets.nextcloud_secrets.path;
      adminuser = "admin";
    };

    # The nginx block has been removed from here, as it must be configured separately.
  };

  # 2. Nginx Reverse Proxy Configuration for Nextcloud
  # This is the correct way to configure the web server for Nextcloud.
  services.nginx = {
    enable = true;
    virtualHosts."nextcloud.labhome.work" = {
      listen = [{
        addr = "0.0.0.0";
        port = 8081; # The port your Cloudflare tunnel points to
      }];
      # This uses the official NixOS helper to configure nginx correctly for Nextcloud
      enableNextcloud = true;
    };
  };
}