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
          "jellyfin.example.com" = "http://localhost:${toString config.my.network.ports.jellyfin}";
          "audiobookshelf.example.com" = "http://localhost:${toString config.my.network.ports.audiobookshelf}";
          "kavita.example.com" = "http://localhost:${toString config.my.network.ports.kavita}";
          "tdarr.example.com" = "http://localhost:${toString config.my.network.ports.tdarr}";
          "transmission.example.com" = "http://${config.my.network.hosts.homeserver}:${toString config.my.network.ports.transmission}";

          # *arr Stack
          "sonarr.example.com" = "http://localhost:${toString config.my.network.ports.sonarr}";
          "radarr.example.com" = "http://localhost:${toString config.my.network.ports.radarr}";
          "lidarr.example.com" = "http://localhost:${toString config.my.network.ports.lidarr}";
          "readarr.example.com" = "http://localhost:${toString config.my.network.ports.readarr}";
          "bazarr.example.com" = "http://localhost:${toString config.my.network.ports.bazarr}";
          "prowlarr.example.com" = "http://localhost:${toString config.my.network.ports.prowlarr}";
          "jellyseerr.example.com" = "http://localhost:${toString config.my.network.ports.jellyseerr}";

          # Productivity
          "paperless.example.com" = "http://localhost:${toString config.my.network.ports.paperless}";
          "miniflux.example.com" = "http://localhost:${toString config.my.network.ports.miniflux}";
          "cal.example.com" = "http://localhost:${toString config.my.network.ports.radicale}";
          "home.example.com" = "http://localhost:${toString config.my.network.ports.homepage}";
          "link.example.com" = "http://localhost:${toString config.my.network.ports.linkwarden}";
          "flare.example.com" = "http://localhost:${toString config.my.network.ports.flare}";

          # Monitoring
          "grafana.example.com" = "http://localhost:${toString config.my.network.ports.grafana}";
          "kuma.example.com" = "http://localhost:${toString config.my.network.ports.uptime-kuma}";

          # Home Automation
          "hass.example.com" = "http://localhost:${toString config.my.network.ports.home-assistant}";

          # Security
          "vault.example.com" = "http://localhost:${toString config.my.network.ports.vaultwarden}";
          "auth.example.com" = "http://localhost:${toString config.my.network.ports.authentik}";

          # AI
          "ollama.example.com" = "http://localhost:${toString config.my.network.ports.ollama}";
        };
      };
    };
  };
}
