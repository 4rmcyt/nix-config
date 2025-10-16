{config, ...}: {
  sops.secrets.vaultwarden_admin_token = {
    sopsFile = ../../../secrets/vaultwarden.yaml;
    key = "vaultwarden_admin_token";
    owner = config.users.users.vaultwarden.name;
    group = config.users.groups.vaultwarden.name;
    mode = "0400";
  };

  sops.secrets.vaultwarden_db_password = {
    sopsFile = ../../../secrets/postgresql.yaml;
    key = "vaultwarden_db_password";
    mode = "0400";
  };

  users.users.vaultwarden = {
    isSystemUser = true;
    group = "vaultwarden";
    extraGroups = ["users"];
  };
  users.groups.vaultwarden = {};

  networking.firewall.allowedTCPPorts = [
    8222 # Vaultwarden
  ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."vault.labhome.work" = {
      forceSSL = true;
      sslCertificate = "/var/lib/acme/labhome.work/fullchain.pem";
      sslCertificateKey = "/var/lib/acme/labhome.work/key.pem";
      locations."/" = {
        proxyWebsockets = true;
        proxyPass = "http://127.0.0.1:8000";
      };
    };
  };
  services.vaultwarden = {
    dbBackend = "postgresql";
    bitwarden-directory-connector-cli.domain = "https://vault.labhome.work";
    vaultwarden.backupDir = "/var/lib/vaultwarden/backup";

    config = {
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "critical";
      DOMAIN = "https://vault.labhome.work";
      SIGNUPS_ALLOWED = true;
      ADMIN_TOKEN = config.sops.secrets.vaultwarden_admin_token.path;
      DATABASE_URL = "postgresql://vaultwarden:${config.sops.secrets.vaultwarden_db_password.path}@/run/postgresql/vaultwarden?sslmode=disable";
      LOG_FILE = "/var/lib/vaultwarden/logs/access.log";

      # SMTP_HOST = "127.0.0.1";
      # SMTP_PORT = 25;
      # SMTP_SSL = false;
      # SMTP_FROM = "vaultwarden@labhome.work";
      # SMTP_FROM_NAME = "labhome.work Vaultwarden server";
    };
  };
}
