{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets = {
    miniflux_admin_password = {
      sopsFile = ../../../secrets/miniflux.yaml;
      key = "miniflux_admin_pass";
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
    config = {
      WORKER_POOL_SIZE = "5"; # number of background workers
      POLLING_FREQUENCY = "60"; # feed refresh interval in minutes
      BATCH_SIZE = "100"; # number of feeds sent to queue each interval
      CREATE_ADMIN = "true"; # create admin user on first run
      ADMIN_USERNAME = 1; # admin username
      ADMIN_PASSWORD = config.sops.secrets.miniflux_creds.path; 
      CLEANUP_ARCHIVE_READ_DAYS = "60"; # read items are removed after x days
      BASE_URL = "https://miniflux.example.com";
      LISTEN_ADDR = "localhost:8086";
      DATABASE_MIGRATIONS = 1; 
      DATABASE_URL = lib.mkForce "postgres://miniflux:${config.sops.secrets.miniflux_db_password.path}@/run/postgresql/miniflux?sslmode=disable";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/miniflux 0755 miniflux miniflux -"
    "d /var/lib/miniflux/cache 0755 miniflux miniflux -"
    "d /var/lib/miniflux/logs 0755 miniflux miniflux -"
    "d /var/lib/miniflux/data 0755 miniflux miniflux -"
  ];
}
