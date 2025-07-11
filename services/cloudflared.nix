{ config, pkgs, ... }:

{
  sops.secrets.cloudflare_tunnel_token = {
    owner = "cloudflared";
    group = "cloudflared";
    mode = "0400";
  };
  
#   sops.secrets."cloudflared/cert".path = "services/cloudflared.nix";
#   sops.secrets."cloudflared/test" = {
#     # Both are "cloudflared" by default
#     owner = config.services.cloudflared.user;
#     group = config.services.cloudflared.group;
# };

  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
    home = "/var/lib/cloudflared";
  };

  users.groups.cloudflared = {};

#   services.cloudflared.tunnels.config.sops.secrets."cloudflared/clouflare_tunnel_id".path = {
#   credentialsFile = config.sops.secrets."cloudflared/test".path;
#   default = "http_status:404";
#   ingress = {
#     "nextcloud.labhome.work" = "http://localhost:8081";
#     "keycloak.labhome.work" = "http://localhost:8080";
#   };
# };
  systemd.services.cloudflared = {
    description = "Cloudflare Tunnel";
    after = [ "network.target" "systemd-tmpfiles-setup.service" ];
    requires = [ "systemd-tmpfiles-setup.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate --config /var/lib/cloudflared/config.yml run --token-file ${config.sops.secrets.cloudflare_tunnel_token.path}";
      Restart = "always";
      RestartSec = "5s";
      User = "cloudflared";
      Group = "cloudflared";
    };
    preStart = ''
      cat > /var/lib/cloudflared/config.yml << EOF
      tunnel: $(cat ${config.sops.secrets.cloudflare_tunnel_token.path})

      ingress:
        - hostname: nextcloud.labhome.work
          service: http://localhost:8081
        - hostname: keycloak.labhome.work
          service: http://localhost:8080
        - hostname: jellyfin.labhome.work
          service: http://localhost:8096
        - hostname: paperless.labhome.work
          service: http://localhost:8888
        - hostname: home.labhome.work
          service: http://localhost:8082
        - hostname: rss.labhome.work
          service: http://localhost:8086
        - hostname: transmission.labhome.work
          service: http://localhost:9091
        - hostname: cal.labhome.work
          service: http://localhost:5232
        - hostname: audiobookshelf.labhome.work
          service: http://localhost:8085
        - hostname: paste.labhome.work
          service: http://localhost:8083
        - hostname: kavita.labhome.work
          service: http://localhost:5000
        - hostname: microbin.labhome.work
          service: http://localhost:8084
        - hostname: hass.labhome.work
          service: http://localhost:8123  
        - service: http_status:404
      EOF
    '';
  };
}