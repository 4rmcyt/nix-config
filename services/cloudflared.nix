{ config, pkgs, ... }:
let
  cloudflareTunnelId = config.sops.secrets.cloudflare_tunnel_id.path;
in
{
  services.cloudflared.tunnels.cloudflareTunnelId = {
    enable = true;
    credentialsFile = config.sops.secrets.cloudflareTunnelCredentials.path;
    default = "http_status:404";
    ingress = {
      "nextcloud.example.com" = "http://localhost:8081";
      "keycloak.example.com" = "http://localhost:8080";
      "jellyfin.example.com" = "http://localhost:8096";
      "paperless.example.com" = "http://localhost:8888";
      "home.example.com" = "http://localhost:8082";
      "rss.example.com" = "http://localhost:8086";
      "hass.example.com" = "http://localhost:8123";
      "miniflux.example.com" = "http://localhost:8086";
      "transmission.example.com" = "http://localhost:9091";
      "cal.example.com" = "http://localhost:5232";
      "audiobookshelf.example.com" = "http://localhost:8085";
      "paste.example.com" = "http://localhost:8083";
      "kavita.example.com" = "http://localhost:5000";
      "microbin.example.com" = "http://localhost:8084";
    };
  };
}
