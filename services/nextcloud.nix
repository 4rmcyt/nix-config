{ config, pkgs, lib, ... }:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;

    hostName = "192.168.1.165";

    # Use local database with trust authentication
    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbname = "nextcloud";
      adminpassFile = config.sops.secrets.nextcloud_admin_password.path;
      adminuser = "admin";
    };

    # System settings
    settings = {
      overwriteprotocol = "http";
      trusted_domains = [ "192.168.1.165" "homeserver.local" ];
      trusted_proxies = [ "127.0.0.1" ];
    };

    nginx = {
      # Listen on 8081 instead of 80/443
      listen = [
        { addr = "127.0.0.1"; port = 8081; ssl = false; }
      ];
    };
  };

  # Override Nextcloud nginx to listen on 127.0.0.1:8081
  services.nginx.virtualHosts."nextcloud.local" = {
    listen = [
      { addr = "127.0.0.1"; port = 8081; ssl = false; }
    ];
    locations."/" = {
      proxyPass = "http://unix:/run/nextcloud/php-fpm.sock";
      extraConfig = ''
        include ${pkgs.nginx}/conf/fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_param HTTPS off;
        fastcgi_pass unix:/run/nextcloud/php-fpm.sock;
        fastcgi_index index.php;
      '';
    };
    root = "/var/lib/nextcloud";
    extraConfig = ''
      client_max_body_size 512M;
    '';
  };

  # Enable nginx for Nextcloud
  services.nginx.enable = true;

  # SOPS secrets for Nextcloud
  sops.secrets.nextcloud_admin_password = {};

  # Open firewall for Nextcloud and nginx
  networking.firewall.allowedTCPPorts = [ 80 443 8081 ];
}
