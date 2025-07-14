{ config, pkgs, ... }:

{
  services.cloudflared = {
    enable = true;
    tunnels = {
      ${config.sops.secrets.cloudflare_tunnel_id.path} = {
        credentialsFile = "${config.sops.secrets.cloudflare_tunnel_credentials.path}";
        ingress = [
          {
            hostname = "nextcloud.labhome.work";
            service = "http://localhost:8081";
          }
          {
            hostname = "keycloak.labhome.work";
            service = "http://localhost:8080";
          }
          {
            hostname = "jellyfin.labhome.work";
            service = "http://localhost:8096";
          }
          {
            hostname = "paperless.labhome.work";
            service = "http://localhost:8888";
          }
          {
            hostname = "home.labhome.work";
            service = "http://localhost:8082";
          }
          {
            hostname = "rss.labhome.work";
            service = "http://localhost:8086";
          }
          {
            hostname = "transmission.labhome.work";
            service = "http://localhost:9091";
          }
          {
            hostname = "cal.labhome.work";
            service = "http://localhost:5232";
          }
          {
            hostname = "audiobookshelf.labhome.work";
            service = "http://localhost:8085";
          }
          {
            hostname = "paste.labhome.work";
            service = "http://localhost:8083";
          }
          {
            hostname = "kavita.labhome.work";
            service = "http://localhost:5000";
          }
          {
            hostname = "microbin.labhome.work";
            service = "http://localhost:8084";
          }
          {
            hostname = "hass.labhome.work";
            service = "http://localhost:8123";
          }
          { service = "http_status:404"; }
        ];
      };

    };
  };
}
