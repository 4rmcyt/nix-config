{ config, pkgs, lib, ... }:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
    hostName = "192.168.1.165";
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
      trusted_domains = [ "192.168.1.165" "homeserver.local" ];
      trusted_proxies = [ "127.0.0.1" ];
    };
  };

  services.nginx.enable = true;

  services.nginx.virtualHosts."nextcloud.local" = {
    listen = [
      { addr = "127.0.0.1"; port = 8081; ssl = false; }
    ];
    root = "/var/lib/nextcloud";
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
    extraConfig = ''
      client_max_body_size 512M;
    '';
  };

  sops.secrets.nextcloud_admin_password = {};
  networking.firewall.allowedTCPPorts = [ 80 443 8081 ];
}
