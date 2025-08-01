{ config, pkgs, ... }:

{
  services.authentik = {
    enable = true;
    domain = "https://authentik.example.com";
    secret_key_file = config.sops.secrets.authentik_secret_key.path;
    createDatabase = false;
     settings = {
        postgresql = {
        user = "authentik";
        name = "authentik";
        host = "localhost";
      };
      email = {
        from = "noreply@example.com";
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
        authentik_host = "https://authentik.example.com";
        listen = "127.0.0.1:8080";
      };
    };
  };

  sservices.nginx.virtualHosts."authentik.example.com" = {
    forceSSL = true;
    enableACME = true;
    http2 = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:9000";
    };
  };

  networking.firewall.allowedTCPPorts = [
    9000  # Authentik
    8080  # Authentik Outpost Proxy
    9100  # Authentik Metrics
  ];

  users.users.authentik = {
    isSystemUser = true;
    group = "authentik";
    extraGroups = [ "users" ];
  };
  users.groups.authentik = { };

  

  sops.secrets = {
    authentik_secret_key = {
      owner = config.users.users.authentik.name;
    };

    authentik_outpost_token = {
      owner = config.users.users.authentik.name;
    };
  };
}
