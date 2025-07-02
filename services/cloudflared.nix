{ config, pkgs, ... }:

{
  sops.secrets.cloudflare_tunnel_token = { };

  systemd.services.cloudflared = {
    enable = true;
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

  # Open firewall for Cloudflared if needed
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}