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
  users.groups.acme = { };
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
      "auth.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:4180";
        };
      };

      "jellyfin.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:8096";
        };
      };
      "paperless.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:8888";
        };
      };
      "home.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:8082";
        };
      };
      "hass.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:8123";
        };
      };
      "transmission.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://192.168.1.165:9091";
        };
      };
      "cal.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:5232";
        };
      };
      "audiobookshelf.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:9292";
        };
      };
      "kavita.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:5000";
        };
      };
      "microbin.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:8084";
        };
      };
      "prowlarr.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:9696";
        };
      };
      "radarr.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:7878";
        };
      };
      "sonarr.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:8989";
        };
      };
      "lidarr.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:8686";
        };
      };
      "bazarr.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:6767";
        };
      };
      "jellyseerr.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:5055";
        };
      };
      "ollama.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:11434";
        };
      };
      "calibre-web.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:8083";
        };
      };
      "vault.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:8222";
        };
      };
      "link.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = "http://localhost:12522";
        };
      };
      "kuma.labhome.work" = {
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
