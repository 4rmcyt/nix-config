{ config, pkgs, ... }:

let
  # The base domain you provided
  baseDomain = "labhome.work";
in
{
  # Enable the cloudflared daemon
  services.cloudflared = {
    enable = true;
    tokenFile = config.sops.secrets.cloudflare_tunnel_token.path;

    tunnels.homeserver = {
      credentialsFile = config.sops.secrets.cloudflare_tunnel_credentials.path;

      # Define how public hostnames map to internal services
      ingress = [
        # Services via Cloudflare Tunnel
        { hostname = "nextcloud.${baseDomain}"; service = "http://localhost:8081"; }
        { hostname = "keycloak.${baseDomain}"; service = "http://localhost:8080"; }
        { hostname = "paste.${baseDomain}"; service = "http://localhost:8083"; }        # microbin
        { hostname = "rss.${baseDomain}"; service = "http://localhost:8084"; }          # miniflux
        { hostname = "cal.${baseDomain}"; service = "http://localhost:5232"; }          # radicale
        { hostname = "jellyfin.${baseDomain}"; service = "http://localhost:8096"; }     # jellyfin
        
        # Services still via Caddy (local access)
        { hostname = "paperless.${baseDomain}"; service = "http://localhost:8082"; }
        { hostname = "audio.${baseDomain}"; service = "http://localhost:8085"; }        # audiobookshelf
        { hostname = "home.${baseDomain}"; service = "http://localhost:8123"; }         # home assistant

        # A catch-all to prevent the tunnel from exposing other services by accident
        { service = "http_status:404"; }
      ];
    };
  };

  # Define the new secrets required for this module
  sops.secrets.cloudflare_tunnel_token = { };
  sops.secrets.cloudflare_tunnel_credentials = { };
}