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
      PORT = "8086";
      RUN_AS_USER = "miniflux";
    };
  };
}
