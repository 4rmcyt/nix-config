{ config, pkgs, lib, ... }:

{
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux_secrets.path;

    config = {
      BASE_URL = "https://rss.labhome.work";
      DATABASE_URL = "postgres://miniflux:${config.sops.secrets.miniflux_db_password.path}@/miniflux";
      PORT = "8086";
      RUN_AS_USER = "miniflux";
    };
  };
}
