{ config, pkgs, ... }:
{
services.cloudflared = {
    enable = true;
    # You MUST add this config block
    config = {
      tunnel = "f7876e26-87a8-4bdd-9798-3986b0f7cebc";
      "credentials-file" = config.sops.secrets.cloudflare_tunnel_credentials.path;
      

      ingress = [
          { hostname = "nextcloud.example.com";      service = "http://localhost:8081"; }
          { hostname = "keycloak.example.com";       service = "http://localhost:8080"; }
          { hostname = "jellyfin.example.com";       service = "http://localhost:8096"; }
          { hostname = "paperless.example.com";      service = "http://localhost:8888"; }
          { hostname = "home.example.com";           service = "http://localhost:8082"; }
          { hostname = "rss.example.com";            service = "http://localhost:8086"; }
          { hostname = "transmission.example.com";   service = "http://localhost:9091"; }
          { hostname = "cal.example.com";            service = "http://localhost:5232"; }
          { hostname = "audiobookshelf.example.com"; service = "http://localhost:8085"; }
          { hostname = "paste.example.com";          service = "http://localhost:8083"; }
          { hostname = "kavita.example.com";         service = "http://localhost:5000"; }
          { hostname = "microbin.example.com";       service = "http://localhost:8084"; }
          { hostname = "hass.example.com";           service = "http://localhost:8123"; }
          { service = "http_status:404"; }
      ];
    };
  };
}