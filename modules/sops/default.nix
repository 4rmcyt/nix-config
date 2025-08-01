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



      "keycloak.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8080"; };
      "jellyfin.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8096"; };
      "paperless.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8888"; };
      "home.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8082"; };
      "rss.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8086"; };
      "hass.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8123"; };
      "miniflux.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8086"; };
      "transmission.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://192.168.1.165:9091"; };
      "cal.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:5232"; };
      "audiobookshelf.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:9292"; };
      "kavita.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:5000"; };
      "microbin.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8084"; };
      "prowlarr.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:9696"; };
      "radarr.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:7878"; };
      "sonarr.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8989"; };
      "lidarr.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8686"; };
      "bazarr.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:6767"; };
      "jellyseerr.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:5055"; };
      "ollama.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:11434"; };
      "calibre-web.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8083"; };
      "vault.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:8222"; };
      "link.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:12522"; };
      "kuma.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:3001"; };
      "lldap.labhome.work" = { forceSSL = true; enableACME = true; locations."/".proxyPass = "http://localhost:17170"; };
    };
  };
}
