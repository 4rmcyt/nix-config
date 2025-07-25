{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.miniflux = {
    enable = true;
    adminCredentialsFile = "/etc/miniflux.env";
    createDatabaseLocally = true; # create database on first run
    config = {
      WORKER_POOL_SIZE = "5"; # number of background workers
      POLLING_FREQUENCY = "60"; # feed refresh interval in minutes
      BATCH_SIZE = "100"; # number of feeds sent to queue each interval
      CLEANUP_ARCHIVE_READ_DAYS = "60"; # read items are removed after x days
      BASE_URL = "https://rss.example.com";
      LISTEN_ADDR = "localhost:8086";
      CREATE_ADMIN = 1; # create an admin user on first run
      DATABASE_MIGRATIONS = 0; # run database migrations on first run
      # DATABASE_URL = lib.mkForce "user=miniflux dbname=miniflux sslmode=disable host=/run/postgresql";
      # DATABASE_URL = lib.mkForce "postgres://postgres:${config.sops.secrets.miniflux_db_password.path}@localhost/miniflux?sslmode=disable";
      # OAUTH2_PROVIDER = "oidc";
      # OAUTH2_CLIENT_ID = "miniflux";
      # OAUTH2_REDIRECT_URL = "https://rss.example.com/oauth2/oidc/callback";
      # OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://keycloak.example.com/realms/master";
      # OAUTH2_USER_CREATION = "1";
      # DISABLE_LOCAL_AUTH = "false";

      # FETCH_YOUTUBE_WATCH_TIME = true;

    };
  };
    systemd.services.miniflux = {
      description = "Miniflux service";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "postgresql.service"
      ];
      requires = [ "postgresql.service" ];
    };
}
