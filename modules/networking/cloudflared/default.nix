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

    cloudflare_tunnel_id = {
      sopsFile = ../../../secrets/cloudflare.yaml;
      key = "cloudflare_tunnel_id";
      owner = config.users.users.cloudflared.name;
      group = config.users.groups.cloudflared.name;
      mode = "0400";
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
      "${config.sops.placeholder.cloudflare_tunnel_id}" = {
        credentialsFile = config.sops.secrets.cloudflare_tunnel_credentials.path;
        default = "http_status:404";
        ingress = {
          "jellyfin.${config.my.defaults.domain}" = "http://localhost:8096";
          "paperless.${config.my.defaults.domain}" = "http://localhost:8888";
          "home.${config.my.defaults.domain}" = "http://localhost:8082";
          "hass.${config.my.defaults.domain}" = "http://localhost:8123";
          "miniflux.${config.my.defaults.domain}" = "http://localhost:8086";
          "transmission.${config.my.defaults.domain}" = "http://192.168.1.165:9091";
          "cal.${config.my.defaults.domain}" = "http://localhost:5232";
          "audiobookshelf.${config.my.defaults.domain}" = "http://localhost:9292";
          "kavita.${config.my.defaults.domain}" = "http://localhost:5000";
          "prowlarr.${config.my.defaults.domain}" = "http://localhost:9696";
          "radarr.${config.my.defaults.domain}" = "http://localhost:7878";
          "sonarr.${config.my.defaults.domain}" = "http://localhost:8989";
          "lidarr.${config.my.defaults.domain}" = "http://localhost:8686";
          "bazarr.${config.my.defaults.domain}" = "http://localhost:6767";
          "jellyseerr.${config.my.defaults.domain}" = "http://localhost:5055";
          "ollama.${config.my.defaults.domain}" = "http://localhost:11434";
          "vault.${config.my.defaults.domain}" = "http://localhost:8222";
          "kuma.${config.my.defaults.domain}" = "http://localhost:3001";
          "auth.${config.my.defaults.domain}" = "http://localhost:9000";
          "grafana.${config.my.defaults.domain}" = "http://localhost:3003";
          "tdarr.${config.my.defaults.domain}" = "http://localhost:8265";
          "readarr.${config.my.defaults.domain}" = "http://localhost:8787";
          "link.${config.my.defaults.domain}" = "http://localhost:3000";
        };
      };
    };
  };
}
