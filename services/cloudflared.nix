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
  systemd.tmpfiles.rules = [
    "d /var/lib/cloudflared 0755 cloudflared cloudflared -"
  ];
  # Create tunnel configuration file
  systemd.services.cloudflared.preStart = ''
  # Ensure directory exists (handled by tmpfiles, but safe to check)
  mkdir -p /var/lib/cloudflared
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
      service: http://localhost:8082
    - hostname: home.labhome.work
      service: http://localhost:8123
    - hostname: rss.labhome.work
      service: http://localhost:8083
    - hostname: deluge.labhome.work
      service: http://localhost:8112
    - hostname: cal.labhome.work
      service: http://localhost:5232
    - hostname: audiobookshelf.labhome.work
      service: http://localhost:8085
    - hostname: paste.labhome.work
      service: http://localhost:8087
    - service: http_status:404

  EOF
'';
}