{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets = {
    miniflux_creds = {
      sopsFile = ../../../secrets/miniflux.yaml;
      key = "miniflux_admin_creds";
      owner = config.users.users.miniflux.name;
      group = config.users.groups.miniflux.name;
      mode = "0400";
      
    };
    miniflux_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "miniflux_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
  };

  users.users.miniflux = {
    isSystemUser = true;
    group = "miniflux";
    extraGroups = [ "users" ];
  };
  users.groups.miniflux = { };

  networking.firewall.allowedTCPPorts = [
    8086 # Miniflux
  ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."miniflux.example.com" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://localhost:8086";
        proxyWebsockets = true;
      };
    };
  };

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
      BASE_URL = "https://miniflux.example.com";
      LISTEN_ADDR = "localhost:8086";
      DATABASE_MIGRATIONS = 1; # run database migrations on first run
      DATABASE_URL = lib.mkForce "user=miniflux password=${config.sops.secrets.miniflux_db_password.path} dbname=miniflux sslmode=disable host=/run/postgresql";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/miniflux 0755 miniflux miniflux -"
    "d /var/lib/miniflux/cache 0755 miniflux miniflux -"
    "d /var/lib/miniflux/logs 0755 miniflux miniflux -"
    "d /var/lib/miniflux/data 0755 miniflux miniflux -"
  ];
}
