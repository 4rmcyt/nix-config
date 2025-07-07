# /etc/nixos/services/cloudflared.nix
#
# Configures a Cloudflare Tunnel to securely expose all services.

{ config, pkgs, ... }:

{
  # == 1. SOPS Secret for Tunnel Credentials ==
  # This makes the tunnel's JSON credentials file available to the service.
  # This is more robust than using a one-time token.
  sops.secrets.cloudflare_tunnel_credentials = {
    owner = "cloudflared";
    group = "cloudflared";
    mode = "0400";
  };

  # == 2. User and Group Setup ==
  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
    home = "/var/lib/cloudflared";
  };
  users.groups.cloudflared = {};

  # == 3. Systemd Service for Cloudflared ==
  systemd.services.cloudflared = {
    description = "Cloudflare Tunnel";
    after = [ "network.target" "sops.service" ]; # <-- Added sops.service dependency
    wantedBy = [ "multi-user.target" ];

    # The preStart script writes the necessary configuration files at runtime.
    preStart = ''
      # Get the Tunnel ID from the credentials file
      TUNNEL_ID=$(${pkgs.jq}/bin/jq -r .TunnelID ${config.sops.secrets.cloudflare_tunnel_credentials.path})

      # Write the credentials to the location cloudflared expects
      cp ${config.sops.secrets.cloudflare_tunnel_credentials.path} /var/lib/cloudflared/$TUNNEL_ID.json

      # Write the main config.yml with all the ingress rules
      cat > /var/lib/cloudflared/config.yml << EOF
      # This file is managed by NixOS.
      # The tunnel UUID is read from the credentials file.
      tunnel: $TUNNEL_ID
      credentials-file: /var/lib/cloudflared/$TUNNEL_ID.json

      # Ingress rules define how hostnames map to local services.
      ingress:
        # Productivity & Personal
        - hostname: nextcloud.labhome.work
          service: http://localhost:8081
        - hostname: paperless.labhome.work
          service: http://localhost:8888
        - hostname: paste.labhome.work
          service: http://localhost:8083
        - hostname: rss.labhome.work
          service: http://localhost:8086
        - hostname: cal.labhome.work
          service: http://localhost:5232

        # Media Services
        - hostname: jellyfin.labhome.work
          service: http://localhost:8096
        - hostname: audiobookshelf.labhome.work
          service: http://localhost:8085
        - hostname: transmission.labhome.work
          service: http://localhost:9091

        # Smart Home & IoT
        - hostname: home.labhome.work
          service: http://localhost:8123
        - hostname: mqtt.labhome.work
          service: tcp://localhost:1883

        # Infrastructure & Security
        - hostname: keycloak.labhome.work
          service: http://localhost:8080
        - hostname: homepage.labhome.work
          service: http://localhost:8082
        - hostname: grafana.labhome.work
          service: http://localhost:3000
        - hostname: prometheus.labhome.work
          service: http://localhost:9090

        # This must be the last rule to catch all other traffic.
        - service: http_status:404
      EOF
    '';

    serviceConfig = {
      # The ExecStart command is now simpler, as all config is in the file.
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run";
      Restart = "always";
      RestartSec = "5s";
      User = "cloudflared";
      Group = "cloudflared";
      # The working directory must be set for cloudflared to find the config.
      WorkingDirectory = "/var/lib/cloudflared";
    };
  };
}