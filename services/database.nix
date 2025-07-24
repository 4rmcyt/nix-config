{ config, pkgs, lib, ... }:

{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    authentication = pkgs.lib.mkForce ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local   all             all                                     peer
      host    all             all             127.0.0.1/32            scram-sha-256
      host    all             all             ::1/128                 scram-sha-256
    '';

    # Use ensureUsers to declaratively manage roles.
    # This is idempotent and will run on every rebuild.
    # We can set the password directly using the path from sops-nix.
    ensureUsers = [
      {
        name = "keycloak";
        # The passwordFile option handles setting the user's password securely.
        passwordFile = config.sops.secrets.keycloak_db_password.path;
      }
      {
        name = "hass";
        passwordFile = config.sops.secrets.hass_db_password.path;
      }
      {
        name = "miniflux";
        passwordFile = config.sops.secrets.miniflux_db_password.path;
      }
    ];

    # Use ensureDatabases to declaratively manage databases.
    ensureDatabases = [
      {
        name = "keycloak";
        owner = "keycloak";
      }
      {
        name = "hass";
        owner = "hass";
      }
      {
        name = "miniflux";
        owner = "miniflux";
      }
    ];


  };

}
