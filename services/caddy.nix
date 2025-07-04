{ config, pkgs, lib, ... }:

{
  services.caddy = {
    enable = true;
    
    globalConfig = ''
      auto_https off
    '';
    
    extraConfig = ''
      # Local network
      http://homeserver.local:80, http://192.168.1.165:80 {
        handle_path /nextcloud* {
          root * /var/www/nextcloud
          php_fastcgi unix//run/phpfpm-nextcloud.sock
          file_server
        }
        
        # Microbin
        handle_path /microbin* {
          reverse_proxy localhost:8083
        }
        
        # Home Assistant
        handle_path /hass* {
          reverse_proxy localhost:8123
        }
        
        # Homepage
        handle_path /homepage* {
          reverse_proxy localhost:8082
        }
        
        # Jellyfin  
        handle_path /jellyfin* {
          reverse_proxy localhost:8096
        }
        
        # Default to homepage
        handle {
          reverse_proxy localhost:8082
        }
      }

      # Cloudflare tunnel expects Nextcloud on 8081 at /
      http://localhost:8081 {
        root * /var/www/nextcloud
        php_fastcgi unix//run/phpfpm-nextcloud.sock
        file_server
      }
    '';
  };
  
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}