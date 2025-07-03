{ config, pkgs, lib, ... }:

{
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    
    # Enhanced service configuration
    services = [
      {
        "Media" = [
          {
            "Jellyfin" = {
              href = "http://192.168.1.165:8096";
              description = "Media Server";
              icon = "jellyfin";
            };
          }
        ];
      }
      {
        "Storage" = [
          {
            "Nextcloud" = {
              href = "http://192.168.1.165:80/nextcloud";
              description = "File Storage & Collaboration";
              icon = "nextcloud";
            };
          }
        ];
      }
      {
        "Tools" = [
          {
            "Microbin" = {
              href = "http://192.168.1.165:80/microbin";
              description = "Pastebin Service";
              icon = "microbin";
            };
          }
        ];
      }
      {
        "Automation" = [
          {
            "Home Assistant" = {
              href = "http://192.168.1.165:8123";
              description = "Home Automation";
              icon = "home-assistant";
            };
          }
        ];
      }
    ];
    
    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
      {
        search = {
          provider = "duckduckgo";
          target = "_blank";
        };
      }
    ];
  };
  
  # Override environment variables
  systemd.services.homepage-dashboard.environment = {
    HOMEPAGE_ALLOWED_HOSTS = lib.mkForce "localhost,127.0.0.1,192.168.1.165,homeserver.local";
  };
  
  networking.firewall.allowedTCPPorts = [ 8082 ];
}
