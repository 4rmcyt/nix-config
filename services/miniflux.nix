{
  config,
  lib,
  pkgs,
  ...
}:

let
  minifluxCredentialsFile = pkgs.writeText "miniflux-credentials-file" ''
    admin:$(cat ${config.sops.secrets.miniflux_admin_password.path})
  '';
in
{
  services.miniflux = {
    enable = true;
    adminCredentialsFile = minifluxCredentialsFile;

    config = {
      BASE_URL = "https://rss.example.com";
      CREATE_ADMIN = "1";
      LISTEN_ADDR = "localhost:8086";
      DATABASE_URL = lib.mkForce "postgres://miniflux:$(cat ${config.sops.secrets.miniflux_db_password.path})@localhost/miniflux?sslmode=disable";
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      OAUTH2_REDIRECT_URL = "https://rss.example.com/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://keycloak.example.com/realms/master";
      OAUTH2_USER_CREATION = "1";
      DISABLE_LOCAL_AUTH = "true";

      ADMIN_USERNAME = "admin";
      ADMIN_PASSWORD = config.sops.secrets.miniflux_admin_password.path;
    };
  };
}
