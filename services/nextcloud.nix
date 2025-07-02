{ config, pkgs, ... }:

{
  sops.secrets.nextcloud_admin_password = { };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud29;
    hostName = "nextcloud.yourdomain.com";
    
    config = {
      dbtype = "pgsql";
      dbhost = "localhost";
      dbname = "nextcloud";
      dbuser = "nextcloud";
      adminpassFile = config.sops.secrets.nextcloud_admin_password.path;
    };
    
    settings = {
      trusted_proxies = [ "127.0.0.1" ];
      overwriteprotocol = "https";
    };
  };

  # Remove PostgreSQL configuration - handled by database.nix
}