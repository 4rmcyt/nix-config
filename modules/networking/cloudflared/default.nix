{ config, ... }:
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
          "jellyfin.example.com" = "http://localhost:8096";
          "paperless.example.com" = "http://localhost:8888";
          "home.example.com" = "http://localhost:8082";
          "hass.example.com" = "http://localhost:8123";
          "miniflux.example.com" = "http://localhost:8086";
          "transmission.example.com" = "http://192.168.1.165:9091";
          "cal.example.com" = "http://localhost:5232";
          "audiobookshelf.example.com" = "http://localhost:9292";
          "kavita.example.com" = "http://localhost:5000";
          "prowlarr.example.com" = "http://localhost:9696";
          "radarr.example.com" = "http://localhost:7878";
          "sonarr.example.com" = "http://localhost:8989";
          "lidarr.example.com" = "http://localhost:8686";
          "bazarr.example.com" = "http://localhost:6767";
          "jellyseerr.example.com" = "http://localhost:5055";
          "ollama.example.com" = "http://localhost:11434";
          "calibre-web.example.com" = "http://localhost:8083";
          "vault.example.com" = "http://localhost:8222";
          "link.example.com" = "http://localhost:12522";
          "kuma.example.com" = "http://localhost:3001";
          "auth.example.com" = "http://localhost:8080";
          "grafana.example.com" = "http://localhost:3000";
        };
      };
    };
  };
}
