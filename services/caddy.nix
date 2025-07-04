{ config, pkgs, lib, ... }:

{
  services.caddy = {
    enable = true;

    globalConfig = ''
      auto_https off
    '';

    extraConfig = ''
      # Homepage ONLY on 80/443
      http://homeserver.local:80, http://192.168.1.165:80 {
        root * /var/www/homepage
        file_server
      }

      # Nextcloud ONLY on 8081
      http://localhost:8081 {
        root * /var/www/nextcloud
        php_fastcgi unix//run/phpfpm-nextcloud.sock
        file_server
      }

      # Microbin ONLY on 8083
      http://localhost:8083 {
        reverse_proxy localhost:8084
      }

      # Jellyfin ONLY on 8096
      http://localhost:8096 {
        reverse_proxy localhost:8096
      }

      # Home Assistant ONLY on 8123
      http://localhost:8123 {
        reverse_proxy localhost:8123
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [ 80 443 8081 8083 8096 8123 ];
}