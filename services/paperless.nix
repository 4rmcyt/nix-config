{ config, pkgs, lib, ... }:

{
  services.paperless = {
    enable = true;
    passwordFile = config.sops.secrets.paperless_admin_password.path;
    settings = {
      PAPERLESS_ADMIN_USER = "admin";
      # The password is now handled by `passwordFile` above, so this line is removed.
      PAPERLESS_URL = "https://paperless.labhome.work";
      PAPERLESS_TIME_ZONE = "America/Edmonton";
      # This URL correctly tells Paperless to use database #1 on the redis instance.
      PAPERLESS_REDIS = "redis://localhost:6379/1";
    };
  };

  # Enable a dedicated redis instance for paperless
  services.redis.servers.paperless = {
    enable = true;
    port = 6379;
    # The invalid 'database = 1;' line has been removed from here.
  };
}
