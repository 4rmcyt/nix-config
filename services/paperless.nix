{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.paperless = {
    enable = true;
    package = pkgs.paperless-ngx.overrideAttrs (oldAttrs: {
      doCheck = false;  
    });
    port = 8888;
    address = "127.0.0.1";
    passwordFile = config.sops.secrets.paperless_admin_password.path;
    settings = {
      PAPERLESS_ADMIN_USER = "admin";
      PAPERLESS_ADMIN_PASSWORD = config.sops.secrets.paperless_admin_password.path;
      PAPERLESS_ALLOWED_HOSTS = "paperless.labhome.work,localhost,127.0.0.1";
      PAPERLESS_URL = "https://paperless.labhome.work";
      PAPERLESS_TIME_ZONE = "America/Edmonton";
      PAPERLESS_DBHOST = "localhost";
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
