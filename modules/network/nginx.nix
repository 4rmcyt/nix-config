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

      
      "auth.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxy_pass = "http://localhost:4180";
          proxy_pass_request_body = "off";
          proxy_set_header Content-Length ""; };
      };

 
      "keycloak.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8080";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "jellyfin.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8096";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "paperless.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8888";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "home.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8082";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "rss.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8086";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "hass.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8123";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "miniflux.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8086";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "transmission.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://192.168.1.165:9091";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "cal.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:5232";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "audiobookshelf.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:9292";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "kavita.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:5000";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "microbin.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8084";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "prowlarr.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:9696";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "radarr.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:7878";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "sonarr.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8989";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "lidarr.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8686";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "bazarr.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:6767";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "jellyseerr.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:5055";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "ollama.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:11434";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "calibre-web.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8083";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "vault.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:8222";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "link.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:12522";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };

      "kuma.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:3001";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
      };


      "auth.labhome.work" = {
        forceSSL = true;
        enableACME = true;
        extraConfig = "auth_request /_auth;";
        locations."/".proxyPass = "http://localhost:9000";
        locations."/_auth" = { internal = true; proxy_pass = "https://auth.labhome.work"; };
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
