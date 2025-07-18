{ config, pkgs, ... }:
{
services.cloudflared = {
    enable = true;
    tunnels = {
      "f7876e26-87a8-4bdd-9798-3986b0f7cebc" = {
        credentials-file = ${config.sops.secrets.cloudflare_tunnel_credentials.path};
        default = "http_status:404";
        ingress = {
          "nextcloud.labhome.work" = { service = "http://localhost:8081"; };
          "keycloak.labhome.work" = { service = "http://localhost:8080"; };
          "jellyfin.labhome.work" = { service = "http://localhost:8096"; };
          "paperless.labhome.work" = { service = "http://localhost:8888"; };
          "home.labhome.work" = { service = "http://localhost:8082"; };
          "rss.labhome.work" = { service = "http://localhost:8086"; };
          "transmission.labhome.work" = { service = "http://localhost:9091"; };
          "cal.labhome.work" = { service = "http://localhost:5232"; };
          "audiobookshelf.labhome.work" = { service = "http://localhost:8085"; };
          "paste.labhome.work" = { service = "http://localhost:8083"; };
          "kavita.labhome.work" = { service = "http://localhost:5000"; };
          "microbin.labhome.work" = { service = "http://localhost:8084"; };
          "hass.labhome.work" = { service = "http://localhost:8123"; };
          default = "http_status:404";
        };
      };
    };
  };
}