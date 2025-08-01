{ config, pkgs, ... }:
{ 
  users.users.nginx = {
    isSystemUser = true;
    group = "acme";
    extraGroups = [
      "users"
      "acme"
    ];
  };
  users.groups.nginx = { };

  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
  };
  
  services.nginx = {
    enable = true;
    group = "nginx";
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    
    statusPage = true;
    virtualHosts = {
      "auth.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:4180";
        };
      };

      "jellyfin.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:8096";
        };
      };
      "paperless.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:8888";
        };
      };
      "home.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:8082";
        };
      };
      "hass.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:8123";
        };
      };
      "transmission.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://192.168.1.165:9091";
        };
      };
      "cal.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:5232";
        };
      };
      "audiobookshelf.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:9292";
        };
      };
      "kavita.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:5000";
        };
      };
      "microbin.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:8084";
        };
      };
      "prowlarr.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:9696";
        };
      };
      "radarr.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:7878";
        };
      };
      "sonarr.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:8989";
        };
      };
      "lidarr.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:8686";
        };
      };
      "bazarr.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:6767";
        };
      };
      "jellyseerr.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:5055";
        };
      };
      "ollama.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:11434";
        };
      };
      "calibre-web.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:8083";
        };
      };
      "vault.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:8222";
        };
      };
      "link.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:12522";
        };
      };
      "kuma.example.com" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:3001";
        };
      };
    };
  };
}
