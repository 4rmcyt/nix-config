{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets = {
    miniflux_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "miniflux_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
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
      sslCertificate = "/var/lib/acme/example.com/fullchain.pem";
      sslCertificateKey = "/var/lib/acme/example.com/key.pem";
      locations."/" = {
        proxyPass = "http://localhost:8086";
        proxyWebsockets = true;
      };
    };
  };

  environment.systemPackages = [ pkgs.miniflux ];
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux_admin_creds.path; # path to admin credentials file
    config = {
      WORKER_POOL_SIZE = "5"; # number of background workers
      POLLING_FREQUENCY = "60"; # feed refresh interval in minutes
      BATCH_SIZE = "100"; # number of feeds sent to queue each interval
      CREATE_ADMIN = 1; # create admin user on first run
      # ADMIN_USERNAME = "admin"; # admin username
      # ADMIN_PASSWORD = config.sops.secrets.miniflux_admin_password.path;
      CLEANUP_ARCHIVE_READ_DAYS = "60"; # read items are removed after x days
      BASE_URL = "https://miniflux.example.com";
      LISTEN_ADDR = "localhost:8086";
      DATABASE_MIGRATIONS = 1;
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
