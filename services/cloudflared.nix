{ config, pkgs, ... }:
{
services.cloudflared = {
    enable = true;
    tunnels = {
      "f7876e26-87a8-4bdd-9798-3986b0f7cebc" = {
        cert-file = "/home/zeev/.cloudflared/cert.pem";
        default = "http_status:404";
        ingress = {
          "nextcloud.example.com" =  "http://localhost:8081";
          "keycloak.example.com" =  "http://localhost:8080";
          "jellyfin.example.com" =  "http://localhost:8096";
          "paperless.example.com" =  "http://localhost:8888";
          "home.example.com" =  "http://localhost:8082";
          "rss.example.com" =  "http://localhost:8086";
          "transmission.example.com" =  "http://localhost:9091";
          "cal.example.com" =  "http://localhost:5232";
          "audiobookshelf.example.com" =  "http://localhost:8085";
          "paste.example.com" =  "http://localhost:8083";
          "kavita.example.com" =  "http://localhost:5000";
          "microbin.example.com" =  "http://localhost:8084";
          "hass.example.com" =  "http://localhost:8123";
          default = "http_status:404";
        };
      };
    };
  };
}