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
      "nextcloud.labhome.work" = "http://localhost:8081";
      "keycloak.labhome.work" = "http://localhost:8080";
      "jellyfin.labhome.work" = "http://localhost:8096";
      "paperless.labhome.work" = "http://localhost:8888";
      "home.labhome.work" = "http://localhost:8082";
      "rss.labhome.work" = "http://localhost:8086";
      "hass.labhome.work" = "http://localhost:8123";
      "miniflux.labhome.work" = "http://localhost:8086";
      "transmission.labhome.work" = "http://localhost:9091";
      "cal.labhome.work" = "http://localhost:5232";
      "audiobookshelf.labhome.work" = "http://localhost:8085";
      "paste.labhome.work" = "http://localhost:8083";
      "kavita.labhome.work" = "http://localhost:5000";
      "microbin.labhome.work" = "http://localhost:8084";
    };
  };
}
