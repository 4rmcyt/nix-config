{ config, pkgs, ... }:

{
  sops.secrets.cloudflare_tunnel_token = { };
  sops.secrets.cloudflare_tunnel_credentials = { };

  services.cloudflared = {
    enable = true;
    user = "cloudflared";
    
    # Use environmentFile instead of tokenFile
    environmentFile = config.sops.secrets.cloudflare_tunnel_token.path;
    
    tunnels = {
      "homeserver" = {
        credentialsFile = config.sops.secrets.cloudflare_tunnel_credentials.path;
        default = "http://localhost:8080";
        
        ingress = {
          "nextcloud.yourdomain.com" = "http://localhost:8080";
          "keycloak.yourdomain.com" = "http://localhost:8081";
          "jellyfin.yourdomain.com" = "http://localhost:8096";
          "paperless.yourdomain.com" = "http://localhost:8082";
          "home.yourdomain.com" = "http://localhost:8123";
        };
      };
    };
  };

  # Ensure cloudflared user exists
  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };
  users.groups.cloudflared = {};
}