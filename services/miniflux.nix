{
  config,
  lib,
  pkgs,
  ...
}:
{ 
  environment.systemPackages = [ pkgs.miniflux ]; 
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux_creds.path; # path to admin credentials file
    createDatabaseLocally = true; # create database on first run
    config = {
      WORKER_POOL_SIZE = "5"; # number of background workers
      POLLING_FREQUENCY = "60"; # feed refresh interval in minutes
      BATCH_SIZE = "100"; # number of feeds sent to queue each interval
      CLEANUP_ARCHIVE_READ_DAYS = "60"; # read items are removed after x days
      BASE_URL = "https://rss.labhome.work";
      LISTEN_ADDR = "localhost:8086";
      DATABASE_MIGRATIONS = 1; # run database migrations on first run
      DATABASE_URL = lib.mkForce "user=miniflux dbname=miniflux sslmode=disable host=/run/postgresql";
    };
  };

  users.miniflux = {
    isSystemUser = true;
    group = "miniflux";
    extraGroups = [ "users" ];
  };
  users.groups.miniflux = {};
  
  systemd.tmpfiles.rules = [
    "d /var/lib/miniflux 0755 miniflux miniflux -"
    "d /var/lib/miniflux/cache 0755 miniflux miniflux -"
    "d /var/lib/miniflux/logs 0755 miniflux miniflux -"
    "d /var/lib/miniflux/data 0755 miniflux miniflux -"
  ];
}  
