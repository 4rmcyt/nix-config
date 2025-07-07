# /etc/nixos/services/cloudflared.nix
#
# Configures a Cloudflare Tunnel to securely expose all services.

{ config, pkgs, ... }:

{
  # == 1. SOPS Secret for Tunnel Credentials ==
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

  # --- ADDED: Declaratively create the directory ---
  # This ensures the directory exists with the correct ownership
  # before the cloudflared service attempts to write to it.
  systemd.tmpfiles.rules = [
    "d /var/lib/cloudflared 0750 cloudflared cloudflared -"
  ];

  # == 3. Systemd Service for Cloudflared ==
  systemd.services.cloudflared = {
    description = "Cloudflare Tunnel";
    # This dependency ensures tmpfiles are created before the service starts.
    after = [ "network.target" "systemd-tmpfiles-setup.service" ];
    requires = [ "systemd-tmpfiles-setup.service" ];
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
      tunnel: $TUNNEL_ID
      credentials-file: /var/lib/cloudflared/$TUNNEL_ID.json

      # Ingress rules define how hostnames map to local services.
      ingress:
        # Productivity & Personal
        - hostname: nextcloud.example.com
          service: http://localhost:8081
        - hostname: paperless.example.com
          service: http://localhost:8888
        - hostname: paste.example.com
          service: http://localhost:8083
        - hostname: rss.example.com
          service: http://localhost:8086
        - hostname: cal.example.com
          service: http://localhost:5232

        # Media Services
        - hostname: jellyfin.example.com
          service: http://localhost:8096
        - hostname: audiobookshelf.example.com
          service: http://localhost:8085
        - hostname: transmission.example.com
          service: http://localhost:9091

        # Smart Home & IoT
        - hostname: home.example.com
          service: http://localhost:8123
        - hostname: mqtt.example.com
          service: tcp://localhost:1883

        # Infrastructure & Security
        - hostname: keycloak.example.com
          service: http://localhost:8080
        - hostname: homepage.example.com
          service: http://localhost:8082
        - hostname: grafana.example.com
          service: http://localhost:3000
        - hostname: prometheus.example.com
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
