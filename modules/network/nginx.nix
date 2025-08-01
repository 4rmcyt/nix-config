{ config, pkgs, ... }:

{
  services.nginx = {
    enable = true;
    proxyWebsockets = true;
    commonHttpConfig = ''
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    '';

    virtualHosts = {
      "_" = {
        default = true;
        listen = [ { addr = "0.0.0.0"; port = 80; } ];
        serverName = "_";
        return = 301 "https://$host$request_uri";
      };

      
      "auth.example.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxy_pass = "http://localhost:4180";
          proxy_pass_request_body = "off";
          proxy_set_header Content-Length "" };
      };

 
      "keycloak.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8080";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "jellyfin.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8096";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "paperless.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8888";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "home.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8082";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "rss.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8086";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "hass.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8123";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "miniflux.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8086";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "transmission.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://192.168.1.165:9091";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "cal.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:5232";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "audiobookshelf.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:9292";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "kavita.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:5000";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "microbin.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8084";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "prowlarr.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:9696";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "radarr.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:7878";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "sonarr.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8989";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "lidarr.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8686";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "bazarr.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:6767";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "jellyseerr.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:5055";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "ollama.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:11434";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "calibre-web.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8083";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "vault.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8222";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "link.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:12522";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };

      "kuma.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:3001";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };


      "auth.example.com" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:9000";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.example.com"; };
      };
    };
  };
  users.users.nginx = {
    isSystemUser = true;
    group = "nginx";
    extraGroups = [ "users" "nginx" "acme" ];
  };
  users.groups.nginx = {};
}
