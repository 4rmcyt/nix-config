{ config, pkgs, ... }:

{
  sops.secrets.miniflux_admin_password = {};

  services.miniflux = {
    enable = true;
    # Remove adminCredentialsFile if you're using ADMIN_USERNAME and ADMIN_PASSWORD directly.
    # adminCredentialsFile = minifluxCredentials; # <-- Remove this line

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

    # Add these explicitly
    environmentVariables = {
      ADMIN_USERNAME = "admin"; # Explicitly set the admin username
      ADMIN_PASSWORD = "${config.sops.secrets.miniflux_admin_password.path}"; # Path to the decrypted password
      # Miniflux will read the content of this file as the password.
    };
  };

  # The tmpfiles rule for 'miniflux-credentials' is no longer needed if you remove adminCredentialsFile
  # and use environmentVariables.
  systemd.tmpfiles.rules = [
    "d /var/lib/miniflux 0755 miniflux miniflux - -"
    # "f ${minifluxCredentials} 0640 miniflux miniflux -" # <-- Remove this line
  ];

  # Ensure the user and group exist
  users.users.miniflux = {
    isSystemUser = true;
    group = "miniflux";
    home = "/var/lib/miniflux";
  };

  users.groups.miniflux = {};
}