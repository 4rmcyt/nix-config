# /etc/nixos/nginx.nix
#
# This file configures Nginx to act as a reverse proxy for all your local services.
# It now uses automatically renewed Let's Encrypt certificates via the ACME module.

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



      "keycloak.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8080"; };
      "jellyfin.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8096"; };
      "paperless.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8888"; };
      "home.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8082"; };
      "rss.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8086"; };
      "hass.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8123"; };
      "miniflux.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8086"; };
      "transmission.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://192.168.1.165:9091"; };
      "cal.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:5232"; };
      "audiobookshelf.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:9292"; };
      "kavita.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:5000"; };
      "microbin.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8084"; };
      "prowlarr.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:9696"; };
      "radarr.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:7878"; };
      "sonarr.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8989"; };
      "lidarr.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8686"; };
      "bazarr.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:6767"; };
      "jellyseerr.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:5055"; };
      "ollama.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:11434"; };
      "calibre-web.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8083"; };
      "vault.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8222"; };
      "link.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:12522"; };
      "kuma.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:3001"; };
      "lldap.example.com" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:17170"; };
    };
  };
}
