{ config, pkgs, ... }:

{
  sops.secrets.cloudflare_tunnel_token = { };

  # Use systemd service instead of the NixOS module which has limited options
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

  # Open firewall ports if needed
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}