{ config, pkgs, lib, ... }:

{
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux_secrets.path;

    config = {
      BASE_URL = "https://rss.example.com";
      DATABASE_URL = "postgres://miniflux:${config.sops.secrets.database_passwords.miniflux_db_password}@/miniflux";
      PORT = "8086";
      RUN_AS_USER = "miniflux";
    };
  };
}
