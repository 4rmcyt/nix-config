{ config, pkgs, ... }:

{
  services.paperless = {
    enable = true;
    # Let the module manage the user and group
    user = "paperless";
    group = "paperless";
    
    settings = {
      PAPERLESS_URL = "https://paperless.example.com";
      PAPERLESS_REDIS = "unix:///run/redis-paperless/redis.sock?db=0";
      PAPERLESS_DBENGINE = "postgresql";
      PAPERLESS_DBHOST = "localhost";
      PAPERLESS_DBNAME = "paperless";
      PAPERLESS_DBUSER = "paperless";
      PAPERLESS_DBPASS_COMMAND = "cat ${config.sops.secrets.paperless_db_password.path}";
      PAPERLESS_ADMIN_USER = "admin";
      PAPERLESS_ADMIN_PASSWORD_COMMAND = "cat ${config.sops.secrets.paperless_admin_password.path}";
    };
  };

  # Ensure Paperless services wait for their dependencies
  systemd.services.paperless-web = {
    after = [ "postgresql.service" "redis-paperless.service" ];
    requires = [ "postgresql.service" "redis-paperless.service" ];
  };
  systemd.services.paperless-consumer = {
    after = [ "postgresql.service" "redis-paperless.service" ];
    requires = [ "postgresql.service" "redis-paperless.service" ];
  };
  systemd.services.paperless-scheduler = {
    after = [ "postgresql.service" "redis-paperless.service" ];
    requires = [ "postgresql.service" "redis-paperless.service" ];
  };
  systemd.services.paperless-task-queue = {
    after = [ "postgresql.service" "redis-paperless.service" ];
    requires = [ "postgresql.service" "redis-paperless.service" ];
  };
}
