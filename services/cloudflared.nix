{ config, pkgs, ... }:
{
  services.cloudflared = {
    enable = true;
    tunnels = {
      "f7876e26f7876e26-87a8-4bdd-9798-3986b0f7cebc" = {
        credentialsFile = config.sops.secrets.cloudflare_tunnel_credentials.path;
        default = "http_status:404";
        ingress = {
          "keycloak.labhome.work" = "http://localhost:8080";
          "jellyfin.labhome.work" = "http://localhost:8096";
          "paperless.labhome.work" = "http://localhost:8888";
          "home.labhome.work" = "http://localhost:8082";
          "rss.labhome.work" = "http://localhost:8086";
          "hass.labhome.work" = "http://localhost:8123";
          "miniflux.labhome.work" = "http://localhost:8086";
          "transmission.labhome.work" = "http://192.168.1.165:9091";
          "cal.labhome.work" = "http://localhost:5232";
          "audiobookshelf.labhome.work" = "http://localhost:9292";
          "kavita.labhome.work" = "http://localhost:5000";
          "microbin.labhome.work" = "http://localhost:8084";
          "prowlarr.labhome.work" = "http://localhost:9696";
          "radarr.labhome.work" = "http://localhost:7878";
          "readarr.labhome.work" = "http://localhost:8787";
          "sonarr.labhome.work" = "http://localhost:8989";
          "lidarr.labhome.work" = "http://localhost:8686";
          "bazarr.labhome.work" = "http://localhost:6767";
          "jellyseerr.labhome.work" = "http://localhost:5055";
          "readarr-audiobook.labhome.work" = "http://localhost:9494";
        };
      };
    };
  };
}
