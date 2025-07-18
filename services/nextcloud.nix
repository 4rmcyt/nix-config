{ config, pkgs, lib, ... }:

{
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

    # Configure Nginx for reverse proxying
    nginx = {
      enable = true;
      virtualHost = {
        hostName = "nextcloud.labhome.work";
        listen = [{
          addr = "0.0.0.0";
          port = 8081; # Nextcloud will be accessible on this port
        }];
      };
    };
  };
}
