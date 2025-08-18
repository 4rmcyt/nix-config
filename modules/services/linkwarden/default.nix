{
  config,
  ...
}:
{
  sops.secrets = {
    linkwarden_settings = {
      sopsFile = ../../secrets/linkwarden.yaml;
      key = "linkwarden_settings";
      owner = "linkwarden";
      group = "linkwarden";
      mode = "0400";
    };
    linkwarden_db_password = {
      sopsFile = ../../secrets/postgresql.yaml;
      key = "linkwarden_db_password";
      mode = "0400";
    };
    linkwarden_authentik_client_secret = {
      sopsFile = ../../secrets/linkwarden.yaml;
      key = "linkwarden_authentik_client_secret";
      owner = "linkwarden";
      group = "linkwarden";
      mode = "0400";
    };
    linkwarden_password = {
      sopsFile = ../../secrets/linkwarden.yaml;
      key = "linkwarden_password";
      owner = "linkwarden";
      group = "linkwarden";
      mode = "0400";
    };
    linkwarden_email_password = {
      sopsFile = ../../secrets/gmail_conf.yaml;
      key = "gmail_password";
      mode = "0400";
    };
  };

  users.users.linkwarden = {
    isSystemUser = true;
    group = "linkwarden";
    extraGroups = [ "users" ];
  };
  users.groups.linkwarden = { };

  networking.firewall.allowedTCPPorts = [
    12522 # Linkwarden
  ];

  # service.nginx.virtualHosts."link.example.com" = {
  #   forceSSL = true;
  #   sslCertificate = "/var/lib/acme/example.com/fullchain.pem";
  #   sslCertificateKey = "/var/lib/acme/example.com/key.pem";
  #   http2 = true;
  #   locations."/" = {
  #     proxyPass = "http://localhost:12522";
  #     proxyWebsockets = true;
  #   };
  # };

  services.linkwarden = {
    enable = true;
    settingsFile = config.sops.secrets.linkwarden_settings.path;
    settings = {
      NEXTAUTH_URL = "http://localhost:12522/api/v1/auth";
      NEXTAUTH_SECRET = config.sops.secrets.linkwarden_password.path;
      # Authentik Settings
      NEXT_PUBLIC_AUTHENTIK_ENABLED = true;
      AUTHENTIK_CUSTOM_NAME = "linkwarden";
      AUTHENTIK_ISSUER = "http://auth.example.com";
      AUTHENTIK_CLIENT_ID = "linkwarden";
      AUTHENTIK_CLIENT_SECRET = config.sops.secrets.linkwarden_authentik_client_secret.path;
      DATABASE_URL = "postgresql://linkwarden:${config.sops.secrets.linkwarden_db_password.path}@/run/postgresql/linkwarden?sslmode=disable";

      # SMTP Settings
      NEXT_PUBLIC_EMAIL_PROVIDER = "smtp";
      EMAIL_FROM = "redacted@example.com";
      EMAIL_SERVER = "smtp.gmail.com";
      EMAIL_PORT = "587";
      EMAIL_USERNAME = "redacted@example.com";
      EMAIL_PASSWORD = config.sops.secrets.path;
      BASE_URL = "http://link.example.com";
    };
  };
}
