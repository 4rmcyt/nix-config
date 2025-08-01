{ config, pkgs, ... }:

{
  sops.secrets = {
      # --- Authentik Secrets ---
      authentik_secret_key = { sopsFile = ../../secrets/authentik.yaml; key = "authentik_secret_key"; owner = "authentik"; group = "authentik"; mode = "0400"; };
      authentik_outpost_token = { sopsFile = ../../secrets/authentik.yaml; key = "authentik_outpost_token"; owner = "authentik"; group = "authentik"; mode = "0400"; };
      authentik_db_password = { sopsFile = ../../secrets/authentik.yaml; key = "authentik_db_password"; owner = "authentik"; group = "authentik"; mode = "0400"; };
  };

  
  users.users.authentik = {
    isSystemUser = true;
    group = "authentik";
    extraGroups = [ "users" ];
  };
  users.groups.authentik = { };
  
  networking.firewall.allowedTCPPorts = [
    9000  # Authentik
    8080  # Authentik Outpost Proxy
    9100  # Authentik Metrics
  ];

  services.nginx.virtualHosts."authentik.labhome.work" = {
    forceSSL = true;
    enableACME = true;
    http2 = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:9000";
    };
  };

  services.authentik = {
    enable = true;
    domain = "https://authentik.labhome.work";
    secret_key_file = config.sops.secrets.authentik_secret_key.path;
    createDatabase = false;
     settings = {
        postgresql = {
        user = "authentik";
        name = "authentik";
        host = "localhost";
      };
      email = {
        from = "noreply@labhome.work";
        host = "smtp.example.com"; # Replace with your SMTP provider
      };
        disable_startup_analytics = true;
        avatars = "initials";
      };
    
    listen = {
      http = "127.0.0.1:9000";
      metrics = "127.0.0.1:9100";
    };


    outposts.proxy = {
      nginx-proxy = {
        enable = true;
        token_file = config.sops.secrets.authentik_outpost_token.path;
        authentik_host = "https://authentik.labhome.work";
        listen = "127.0.0.1:8080";
      };
    };
  };

  
}
