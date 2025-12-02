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
      ingress:
        - hostname: jellyfin.${config.my.defaults.domain}
          service: http://localhost:8096
        - hostname: home.${config.my.defaults.domain}
          service: http://localhost:8082
        - hostname: miniflux.${config.my.defaults.domain}
          service: http://localhost:8086
        - hostname: transmission.${config.my.defaults.domain}
          service: http://${config.my.defaults.homeserver_lan}:9091
        - hostname: audiobookshelf.${config.my.defaults.domain}
          service: http://localhost:9292
        - hostname: kavita.${config.my.defaults.domain}
          service: http://localhost:5000
        - hostname: prowlarr.${config.my.defaults.domain}
          service: http://localhost:9696
        - hostname: radarr.${config.my.defaults.domain}
          service: http://localhost:7878
        - hostname: sonarr.${config.my.defaults.domain}
          service: http://localhost:8989
        - hostname: lidarr.${config.my.defaults.domain}
          service: http://localhost:8686
        - hostname: bazarr.${config.my.defaults.domain}
          service: http://localhost:6767
        - hostname: jellyseerr.${config.my.defaults.domain}
          service: http://localhost:5055
        - hostname: vault.${config.my.defaults.domain}
          service: http://localhost:8222
        - hostname: kuma.${config.my.defaults.domain}
          service: http://localhost:3001
        - hostname: auth.${config.my.defaults.domain}
          service: http://localhost:9000
        - hostname: grafana.${config.my.defaults.domain}
          service: http://localhost:3003
        - hostname: readarr.${config.my.defaults.domain}
          service: http://localhost:8787
        - hostname: atuin.${config.my.defaults.domain}
          service: http://localhost:8881
        - hostname: microbin.${config.my.defaults.domain}
          service: http://localhost:8069
        - hostname: oauth2-proxy.${config.my.defaults.domain}
          service: http://localhost:4180
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

