{config, ...}: {
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
    extraGroups = ["users"];
  };
  users.groups.cloudflared = {};

  services.cloudflared = {
    enable = true;
    tunnels = {
      "f7876e26f7876e26-87a8-4bdd-9798-3986b0f7cebc" = {
        credentialsFile = config.sops.secrets.cloudflare_tunnel_credentials.path;
        default = "http_status:404";
        ingress = {
          # Media Services
          "jellyfin.labhome.work" = "http://localhost:${toString config.my.network.ports.jellyfin}";
          "audiobookshelf.labhome.work" = "http://localhost:${toString config.my.network.ports.audiobookshelf}";
          "kavita.labhome.work" = "http://localhost:${toString config.my.network.ports.kavita}";
          "tdarr.labhome.work" = "http://localhost:${toString config.my.network.ports.tdarr}";
          "transmission.labhome.work" = "http://${config.my.network.hosts.homeserver}:${toString config.my.network.ports.transmission}";

          # *arr Stack
          "sonarr.labhome.work" = "http://localhost:${toString config.my.network.ports.sonarr}";
          "radarr.labhome.work" = "http://localhost:${toString config.my.network.ports.radarr}";
          "lidarr.labhome.work" = "http://localhost:${toString config.my.network.ports.lidarr}";
          "readarr.labhome.work" = "http://localhost:${toString config.my.network.ports.readarr}";
          "bazarr.labhome.work" = "http://localhost:${toString config.my.network.ports.bazarr}";
          "prowlarr.labhome.work" = "http://localhost:${toString config.my.network.ports.prowlarr}";
          "jellyseerr.labhome.work" = "http://localhost:${toString config.my.network.ports.jellyseerr}";

          # Productivity
          "paperless.labhome.work" = "http://localhost:${toString config.my.network.ports.paperless}";
          "miniflux.labhome.work" = "http://localhost:${toString config.my.network.ports.miniflux}";
          "cal.labhome.work" = "http://localhost:${toString config.my.network.ports.radicale}";
          "home.labhome.work" = "http://localhost:${toString config.my.network.ports.homepage}";
          "link.labhome.work" = "http://localhost:${toString config.my.network.ports.linkwarden}";
          "flare.labhome.work" = "http://localhost:${toString config.my.network.ports.flare}";

          # Monitoring
          "grafana.labhome.work" = "http://localhost:${toString config.my.network.ports.grafana}";
          "kuma.labhome.work" = "http://localhost:${toString config.my.network.ports.uptime-kuma}";

          # Home Automation
          "hass.labhome.work" = "http://localhost:${toString config.my.network.ports.home-assistant}";

          # Security
          "vault.labhome.work" = "http://localhost:${toString config.my.network.ports.vaultwarden}";
          "auth.labhome.work" = "http://localhost:${toString config.my.network.ports.authentik}";

          # AI
          "ollama.labhome.work" = "http://localhost:${toString config.my.network.ports.ollama}";
        };
      };
    };
  };
}
