{ config, pkgs, ... }:

{
  sops.secrets.cloudflare_tunnel_token = { };

  # Cloudflare Tunnel configuration with direct routing
  systemd.services.cloudflared = {
    description = "Cloudflare Tunnel";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file ${config.sops.secrets.cloudflare_tunnel_token.path}";
      Restart = "always";
      RestartSec = "5s";
      User = "cloudflared";
      Group = "cloudflared";
      DynamicUser = true;
    };
  };

  # Create tunnel configuration file
  systemd.services.cloudflared.preStart = ''
    mkdir -p /etc/cloudflared
    cat > /etc/cloudflared/config.yml << EOF
    tunnel: $(cat ${config.sops.secrets.cloudflare_tunnel_token.path})
    
    ingress:
      - hostname: nextcloud.yourdomain.com
        service: http://localhost:8080
      - hostname: keycloak.yourdomain.com
        service: http://localhost:8081
      - hostname: jellyfin.yourdomain.com
        service: http://localhost:8096
      - hostname: paperless.yourdomain.com
        service: http://localhost:8082
      - hostname: home.yourdomain.com
        service: http://localhost:8123
      - hostname: rss.yourdomain.com
        service: http://localhost:8083
      - hostname: deluge.yourdomain.com
        service: http://localhost:8112
      - hostname: cal.yourdomain.com
        service: http://localhost:5232
      - service: http_status:404
    EOF
  '';
}