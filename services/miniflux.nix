{ config, lib, pkgs, ... }:

let
  minifluxCredentialsFile = pkgs.writeText "miniflux-credentials-file" ''
    admin:$(cat ${config.sops.secrets.miniflux_admin_password.path})
  '';
in
{
  sops.secrets.miniflux_admin_password = {};

  services.miniflux = {
    enable = true;
    adminCredentialsFile = minifluxCredentialsFile;

    config = {
      BASE_URL = "https://miniflux.labhome.work";
      CREATE_ADMIN = "1";
      LISTEN_ADDR = "127.0.0.1:8086";
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      OAUTH2_REDIRECT_URL = "https://miniflux.labhome.work/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://keycloak.labhome.work/realms/master";
      OAUTH2_USER_CREATION = "1";
      DISABLE_LOCAL_AUTH = "true";

      ADMIN_USERNAME = "admin";
      # CHANGE THIS LINE BACK: Pass the path to the secret, not its content.
      # Miniflux knows to read the file if the value is a path.
      ADMIN_PASSWORD = config.sops.secrets.miniflux_admin_password.path;
    };
  };
  
  systemd.tmpfiles.rules = [
    "d /var/lib/miniflux 0755 miniflux miniflux - -"
    "f ${minifluxCredentialsFile} 0640 miniflux miniflux -"
  ];

  users.users.miniflux = {
    isSystemUser = true;
    group = "miniflux";
    home = "/var/lib/miniflux";
  };

  users.groups.miniflux = {};
}