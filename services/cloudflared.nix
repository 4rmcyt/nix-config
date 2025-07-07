{ config, pkgs, ... }:

{
  sops.secrets.cloudflare_tunnel_token = {
    owner = "cloudflared";
    group = "cloudflared";
    mode = "0400";
  };

  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
    home = "/var/lib/cloudflared";
  };

  users.groups.cloudflared = {};

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
        - hostname: nextcloud.example.com
          service: http://localhost:8081
        - hostname: keycloak.example.com
          service: http://localhost:8080
        - hostname: jellyfin.example.com
          service: http://localhost:8096
        - hostname: paperless.example.com
          service: http://localhost:8082
        - hostname: home.example.com
          service: http://localhost:8123
        - hostname: rss.example.com
          service: http://localhost:8083
        - hostname: transmission.example.com
          service: http://localhost:9091
        - hostname: cal.example.com
          service: http://localhost:5232
        - hostname: audiobookshelf.example.com
          service: http://localhost:8085
        - hostname: paste.example.com
          service: http://localhost:8087
         - hostname: kavita.example.com
          service: http://localhost:5000
        - service: http_status:404

      EOF
    '';
  };
}