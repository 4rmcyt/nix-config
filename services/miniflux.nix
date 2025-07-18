{ config, pkgs, lib, ... }:

{
  services.miniflux = {
    enable = true;
    # This correctly points to the file containing the admin user/pass.
    adminCredentialsFile = config.sops.secrets.miniflux_secrets.path;

    config = {
      BASE_URL = "https://rss.labhome.work";
      # This is the corrected line. It now correctly gets the password
      # value from within your 'database_passwords' secret group.
      DATABASE_URL = "postgres://miniflux:${config.sops.secrets.database_passwords.miniflux_db_password}@/miniflux";
      PORT = "8086";
      RUN_AS_USER = "miniflux";
    };
  };
}
