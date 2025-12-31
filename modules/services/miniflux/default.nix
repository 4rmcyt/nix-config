{
  config,
  lib,
  pkgs,
  ...
}: {
  sops.secrets = {
    miniflux_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "miniflux_db_password";
      owner = config.users.users.postgres.name;
      group = config.users.groups.postgres.name;
      mode = "0400";
    };
    miniflux_admin_creds = {
      sopsFile = ../../../secrets/miniflux.env;
      key = "miniflux_admin_creds";
      owner = config.users.users.miniflux.name;
      group = config.users.groups.miniflux.name;
      mode = "0600";
      format = "dotenv";
    };
    miniflux_oidc_client_secret = {
      sopsFile = ../../../secrets/authelia.yaml;
      key = "miniflux_oidc_client_secret";
      owner = config.users.users.miniflux.name;
      group = config.users.groups.miniflux.name;
      mode = "0400";
    };
  };

  users.users.miniflux = {
    isSystemUser = true;
    group = "miniflux";
    extraGroups = ["users"];
  };
  users.groups.miniflux = {};

  networking.firewall.allowedTCPPorts = [
    8086 # Miniflux
  ];

  environment.systemPackages = [pkgs.miniflux];
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux_admin_creds.path; # path to admin credentials file
    config = {
      WORKER_POOL_SIZE = "5"; # number of background workers
      POLLING_FREQUENCY = "60"; # feed refresh interval in minutes
      BATCH_SIZE = "100"; # number of feeds sent to queue each interval
      CREATE_ADMIN = 1; # create admin user on first run
      CLEANUP_ARCHIVE_READ_DAYS = "60"; # read items are removed after x days
      BASE_URL = "https://miniflux.${config.my.defaults.domain}"; # base URL for generating links
      LISTEN_ADDR = "localhost:8086";
      DATABASE_MIGRATIONS = 1;
      DATABASE_URL = lib.mkForce "user=miniflux password=${config.sops.secrets.miniflux_db_password.path} dbname=miniflux sslmode=disable host=/run/postgresql";

      # OIDC Authentication via Authelia
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      OAUTH2_CLIENT_SECRET_FILE = config.sops.secrets.miniflux_oidc_client_secret.path;
      OAUTH2_REDIRECT_URL = "https://miniflux.${config.my.defaults.domain}/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://auth.${config.my.defaults.domain}";
      OAUTH2_USER_CREATION = "1";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/miniflux 0755 miniflux miniflux -"
    "d /var/lib/miniflux/cache 0755 miniflux miniflux -"
    "d /var/lib/miniflux/logs 0755 miniflux miniflux -"
    "d /var/lib/miniflux/data 0755 miniflux miniflux -"
  ];
}
