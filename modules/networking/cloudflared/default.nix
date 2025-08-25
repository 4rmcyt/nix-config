{
  config,
  ...
}:
{
  sops.secrets = {
    cloudflare_tunnel_credentials = {
      sopsFile = ../../../secrets/cloudflare_tunnel_credentials.bin;
      key = "credentials";
      owner = config.users.users.cloudflared.name;
      group = config.users.groups.cloudflared.name;
      mode = "0400";
      format = "binary";
    };
  };

  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
    extraGroups = [ "users" ];
  };
  users.groups.cloudflared = { };

  services.cloudflared = {
    enable = true;
    tunnels = {
      "f7876e26f7876e26-87a8-4bdd-9798-3986b0f7cebc" = {
        credentialsFile = config.sops.secrets.cloudflare_tunnel_credentials.path;
        default = "http_status:404";
        ingress = {
          "jellyfin.labhome.work" = "http://localhost:8096";
          "paperless.labhome.work" = "http://localhost:8888";
          "home.labhome.work" = "http://localhost:8082";
          "hass.labhome.work" = "http://localhost:8123";
          "miniflux.labhome.work" = "http://localhost:8086";
          "transmission.labhome.work" = "http://192.168.1.165:9091";
          "cal.labhome.work" = "http://localhost:5232";
          "audiobookshelf.labhome.work" = "http://localhost:9292";
          "kavita.labhome.work" = "http://localhost:5000";
          "prowlarr.labhome.work" = "http://localhost:9696";
          "radarr.labhome.work" = "http://localhost:7878";
          "sonarr.labhome.work" = "http://localhost:8989";
          "lidarr.labhome.work" = "http://localhost:8686";
          "bazarr.labhome.work" = "http://localhost:6767";
          "jellyseerr.labhome.work" = "http://localhost:5055";
          "ollama.labhome.work" = "http://localhost:11434";
          "calibre-web.labhome.work" = "http://localhost:8083";
          "vault.labhome.work" = "http://localhost:8222";
          "link.labhome.work" = "http://localhost:12522";
          "kuma.labhome.work" = "http://localhost:3001";
          "auth.labhome.work" = "http://localhost:9000";
          "grafana.labhome.work" = "http://localhost:3000";
        };
      };
    };
  };
}
