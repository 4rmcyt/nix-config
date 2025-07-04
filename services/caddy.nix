{ config, pkgs, lib, ... }:

{
  services.caddy = {
    enable = true;
    
    globalConfig = ''
      auto_https off
    '';
    
    extraConfig = ''
      # Main homepage       
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
          reverse_proxy localhost:80
        }
      }
    '';
  };
  
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
