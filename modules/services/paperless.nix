{
  config,
  pkgs,
  lib,
  ...
}:

{ 
  sops.secrets = {
    # --- Paperless Secrets ---
    paperless_admin_password = {
      sopsFile = ../../secrets/paperless_secrets.yaml;
      key = "paperless_admin_password";
      owner = "paperless";
      group = "paperless";
      mode = "0400";
    };
    paperless_db_password = {
      sopsFile = ../../secrets/paperless_secrets.yaml;
      key = "paperless_db_password";
      owner = "paperless";
      group = "paperless";
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
    6379 # Redis (for Paperless)
  ];

  services.nginx.virtualHosts."paperless.example.com" = {
    forceSSL = true;
    enableACME = true;
    http2 = true;
    locations."/" = {
      proxyPass = "http://localhost:8888";
      proxyWebsockets = true;
      proxyHeaders = {
        "X-Forwarded-For" = "$proxy_add_x_forwarded_for";
        "X-Forwarded-Proto" = "https";
      };
    };
  };

  services.paperless = {
    enable = true;
    package = pkgs.paperless-ngx.overrideAttrs (oldAttrs: {
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
      PAPERLESS_REDIS = "redis://localhost:6379/1";
      PAPERLESS_OCR_LANGUAGE = "eng+heb+rus+ukr";
      PAPERLESS_OCR_USER_ARGS = {
        optimize = 1;
        pdfa_image_compression = "lossless";
      };
    };
  };
   
  services.redis.servers.paperless = {
    enable = true;
    port = 6379;
  };  
}
