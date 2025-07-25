{ config, pkgs, lib, ... }:

{
  services.paperless = {
    enable = true;
    passwordFile = config.sops.secrets.paperless_admin_password.path;
    settings = {
      PAPERLESS_ADMIN_USER = "admin";
      PAPERLESS_PORT = 8888;
      PAPERLESS_URL = "https://paperless.labhome.work";
      PAPERLESS_TIME_ZONE = "America/Edmonton";
      PAPERLESS_REDIS = "redis://localhost:6379/1";
    };
  };

  services.redis.servers.paperless = {
    enable = true;
    port = 6379;
  };
}
