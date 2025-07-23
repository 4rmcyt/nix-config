{ config, pkgs, ... }:
{
  services.cloudflared = {
    enable = true;
    tunnels = {
      "f7876e26f7876e26-87a8-4bdd-9798-3986b0f7cebc" = {
        credentialsFile = config.sops.secrets.cloudflare_tunnel_credentials.path;
        default = "http_status:404";
        ingress = {
          "keycloak.example.com" = "http://localhost:8080";
          "jellyfin.example.com" = "http://localhost:8096";
          "paperless.example.com" = "http://localhost:8888";
          "home.example.com" = "http://localhost:8082";
          "rss.example.com" = "http://localhost:8086";
          "hass.example.com" = "http://localhost:8123";
          "miniflux.example.com" = "http://localhost:8086";
          "transmission.example.com" = "http://localhost:9091";
          "cal.example.com" = "http://localhost:5232";
          "audiobookshelf.example.com" = "http://localhost:9292";
          "paste.example.com" = "http://localhost:8083";
          "kavita.example.com" = "http://localhost:5000";
          "microbin.example.com" = "http://localhost:8084";
          "prowlarr.example.com" = "http://localhost:9696";
          "radarr.example.com" = "http://localhost:7878";
          "readarr.example.com" = "http://localhost:8787";
          "sonarr.example.com" = "http://localhost:8989";
          "lidarr.example.com" = "http://localhost:8686";
          "bazarr.example.com" = "http://localhost:6767";
          "jellyseerr.example.com" = "http://localhost:5055";
          "sabnzbd.example.com" = "http://localhost:6336";
        };
      };
    };
  };
}
