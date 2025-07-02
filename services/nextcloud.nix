{ config, pkgs, ... }:

{
  sops.secrets.nextcloud_admin_password = { };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud29;
    hostName = "nextcloud.yourdomain.com";
    
    config = {
      dbtype = "pgsql";
      adminpassFile = config.sops.secrets.nextcloud_admin_password.path;
    };
    
    settings = {
      trusted_proxies = [ "127.0.0.1" ];
      overwriteprotocol = "https";
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [
      {
        name = "nextcloud";
        ensureDBOwnership = true;
      }
    ];
  };
}