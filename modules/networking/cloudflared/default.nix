{
  config,
  pkgs,
  ...
}: {
  sops.secrets = {
    cloudflare_tunnel_credentials = {
      sopsFile = ../../../secrets/cloudflare_tunnel_credentials.bin;
      key = "credentials";
      owner = "cloudflared";
      group = "cloudflared";
      mode = "0400";
      format = "binary";
    };

    cloudflare_tunnel_id = {
      sopsFile = ../../../secrets/cloudflare.yaml;
      key = "cloudflare_tunnel_id";
      owner = "cloudflared";
      group = "cloudflared";
      mode = "0400";
    };
  };

  sops.templates."cloudflared-config.yml" = {
    owner = "cloudflared";
    group = "cloudflared";
    mode = "0400";
    content = ''
      tunnel: ${config.sops.placeholder.cloudflare_tunnel_id}
      credentials-file: ${config.sops.secrets.cloudflare_tunnel_credentials.path}

      # Enable WebSocket support for all services
      warp-routing:
        enabled: false

      # Global origin request settings to prevent QUIC timeouts
      originRequest:
        connectTimeout: 30s
        tcpKeepAlive: 30s
        keepAliveTimeout: 90s
        keepAliveConnections: 100
        noHappyEyeballs: false
        # Enable TLS for last-mile encryption to Traefik
        originServerName: ${config.my.defaults.domain}
        noTLSVerify: true  # Using self-signed cert, can be set to false with proper CA

      ingress:
        # ALL services routed through Traefik with TLS (last-mile encryption)
        # Traefik handles authentication (OIDC or forward auth) and TLS termination

        # Nixarr services (forward auth via Authelia)
        - hostname: sonarr.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: sonarr.${config.my.defaults.domain}
        - hostname: radarr.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: radarr.${config.my.defaults.domain}
        - hostname: prowlarr.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: prowlarr.${config.my.defaults.domain}
        - hostname: bazarr.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: bazarr.${config.my.defaults.domain}
        - hostname: lidarr.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: lidarr.${config.my.defaults.domain}
        - hostname: readarr.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: readarr.${config.my.defaults.domain}
        - hostname: jellyseerr.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: jellyseerr.${config.my.defaults.domain}

        # Services with OIDC support (now through Traefik for consistent TLS)
        - hostname: jellyfin.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: jellyfin.${config.my.defaults.domain}
        - hostname: qb.${config.my.defaults.domain}
          service: https://localhost:8081
          originRequest:
            httpHostHeader: qb.${config.my.defaults.domain}
        - hostname: grafana.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: grafana.${config.my.defaults.domain}
        - hostname: miniflux.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: miniflux.${config.my.defaults.domain}
        - hostname: kavita.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: kavita.${config.my.defaults.domain}
        - hostname: audiobookshelf.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: audiobookshelf.${config.my.defaults.domain}

        # Other services
        - hostname: home.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: home.${config.my.defaults.domain}
        - hostname: microbin.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: microbin.${config.my.defaults.domain}
        - hostname: auth.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: auth.${config.my.defaults.domain}

        # Infrastructure services (can be added to Traefik later if needed)
        - hostname: vault.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: vault.${config.my.defaults.domain}
        - hostname: kuma.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: kuma.${config.my.defaults.domain}
        - hostname: lldap.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: lldap.${config.my.defaults.domain}
        - hostname: atuin.${config.my.defaults.domain}
          service: https://localhost:8443
          originRequest:
            httpHostHeader: atuin.${config.my.defaults.domain}
        - hostname: livesync.${config.my.defaults.domain}
          service: https://localhost:8443
        - hostname: livesync.${config.my.defaults.domain}
          originRequest:
            httpHostHeader: livesync.${config.my.defaults.domain}
        - hostname: sabnzbd.${config.my.defaults.domain}
          service: http://localhost:8083
          originRequest:
            httpHostHeader: sabnzbd.${config.my.defaults.domain}

        # Catch-all
        - service: http_status:404
    '';
  };

  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };
  users.groups.cloudflared = {};

  systemd.services.cloudflared = {
    after = [
      "network.target"
      "network-online.target"
      "sops-nix.service"
    ];
    wants = [
      "network.target"
      "network-online.target"
    ];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      User = "cloudflared";
      Group = "cloudflared";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --config ${
        config.sops.templates."cloudflared-config.yml".path
      } --no-autoupdate run";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
# - hostname: loki.${config.my.defaults.domain}
#   service: http://localhost:3100
# - hostname: ollama.${config.my.defaults.domain}
#   service: http://localhost:11434
# - hostname: hass.${config.my.defaults.domain}
#   service: http://localhost:8123
# - hostname: paperless.${config.my.defaults.domain}
#   service: http://localhost:8888
# - hostname: tdarr.${config.my.defaults.domain}
# #   service: http://localhost:8265
# - hostname: cal.${config.my.defaults.domain}
#           service: http://localhost:5232
