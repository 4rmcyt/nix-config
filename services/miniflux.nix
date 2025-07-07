{ config, pkgs, ... }:

let

  minifluxCredentials = pkgs.writeText "miniflux-credentials" ''
    admin:$(cat ${config.sops.secrets.miniflux_admin_password.path})
  '';
in
{
  sops.secrets.miniflux_admin_password = {};

  services.miniflux = {
    enable = true;
      adminCredentialsFile = cfg.adminCredentialsFile;
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
      };
  };
    # Ensure the credentials file is created with the correct permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/miniflux 0755 miniflux miniflux - -"
    "f ${minifluxCredentials} 0640 miniflux miniflux -"
  ];

  # Ensure the user and group exist
  users.users.miniflux = {
    isSystemUser = true;
    group = "miniflux";
    home = "/var/lib/miniflux";
  };

  users.groups.miniflux = {};

}