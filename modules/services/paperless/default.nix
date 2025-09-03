{
  config,
  pkgs,
  ...
}:
{
  sops.secrets = {
    # --- Paperless Secrets ---
    paperless_admin_password = {
      sopsFile = ../../../secrets/paperless.yaml;
      key = "paperless_admin_password";
      owner = config.users.users.paperless.name;
      group = config.users.groups.paperless.name;
      mode = "0400";
    };
    paperless_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "paperless_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
    redis_password = {
      sopsFile = ../../../secrets/redis.yaml;
      key = "redis_password";
      owner = config.users.users.redis.name;
      group = config.users.groups.redis.name;
      mode = "0400";
    };
  };

  users.users.paperless = {
    isSystemUser = true;
    group = "paperless";
    extraGroups = [ "users" ];
  };
  users.groups.paperless = { };

  networking.firewall.allowedTCPPorts = [
    8888 # Paperless
  ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."paperless.example.com" = {
      forceSSL = true;
      sslCertificate = "/var/lib/acme/example.com/fullchain.pem";
      sslCertificateKey = "/var/lib/acme/example.com/key.pem";
      locations."/" = {
        proxyPass = "http://localhost:8888";
        proxyWebsockets = true;
      };
    };
  };
  services.paperless = {
    enable = true;
    domain = "paperless.example.com";
    package = pkgs.paperless-ngx.overrideAttrs (_oldAttrs: {
      doCheck = false;
    });
    port = 8888;
    address = "127.0.0.1";
    passwordFile = config.sops.secrets.paperless_admin_password.path;
    settings = {
      PAPERLESS_CONSUMER_IGNORE_PATTERN = [
        ".DS_STORE/*"
        "desktop.ini"
      ];
      PAPERLESS_ADMIN_USER = "admin";
      PAPERLESS_ALLOWED_HOSTS = "paperless.example.com,localhost,127.0.0.1";
      PAPERLESS_URL = "https://paperless.example.com";
      PAPERLESS_TIME_ZONE = "America/Edmonton";
      PAPERLESS_DBHOST = "/run/postgresql";
      PAPERLESS_DBPORT = 5432;
      PAPERLESS_DBNAME = "paperless";
      PAPERLESS_DBUSER = "paperless";
      PAPERLESS_DBPASS = config.sops.secrets.paperless_db_password.path;
      PAPERLESS_DBENGINE = "postgresql";
      PAPERLESS_REDIS = "redis://redis:${config.sops.secrets.redis_password.path}@/run/redis";
      PAPERLESS_REDIS_PREFIX = "paperless";
      PAPERLESS_OCR_LANGUAGE = "eng+heb+rus+ukr";
      PAPERLESS_OCR_USER_ARGS = {
        optimize = 1;
        pdfa_image_compression = "lossless";
      };
    };
  };
}
