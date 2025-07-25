{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux_credentials.path;
    config = {
      WORKER_POOL_SIZE = "5"; # number of background workers
      POLLING_FREQUENCY = "60"; # feed refresh interval in minutes
      BATCH_SIZE = "100"; # number of feeds sent to queue each interval
      CLEANUP_ARCHIVE_READ_DAYS = "60"; # read items are removed after x days
      BASE_URL = "https://rss.labhome.work";
      CREATE_ADMIN = 0;
      LISTEN_ADDR = "localhost:8086";
      DATABASE_URL = lib.mkForce "user=miniflux host=/run/postgresql dbname=miniflux password=${config.sops.secrets.miniflux_db_password.path} sslmode=disable";
      # DATABASE_URL = lib.mkForce "postgres://postgres:${config.sops.secrets.miniflux_db_password.path}@localhost/miniflux?sslmode=disable";
      # OAUTH2_PROVIDER = "oidc";
      # OAUTH2_CLIENT_ID = "miniflux";
      # OAUTH2_REDIRECT_URL = "https://rss.labhome.work/oauth2/oidc/callback";
      # OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://keycloak.labhome.work/realms/master";
      # OAUTH2_USER_CREATION = "1";
      # DISABLE_LOCAL_AUTH = "false";
    };
  };
}