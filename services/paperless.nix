{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.paperless = {
    enable = true;
    port = 8888;
    address = "127.0.0.1";
    passwordFile = config.sops.secrets.paperless_admin_password.path;
    settings = {
      PAPERLESS_ADMIN_USER = "admin";
      PAPERLESS_PORT = 8888;
      PAPERLESS_ALLOWED_HOSTS = "paperless.example.com,localhost,127.0.0.1";
      PAPERLESS_URL = "https://paperless.example.com";
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
