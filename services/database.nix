# In your postgresql.nix
{ config, pkgs, ... }:

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

    # The declarative NixOS way to manage users and databases.
    # This replaces your initialScript and the custom systemd service.
    ensureUsers = [
      {
        name = "keycloak";
        # This correctly reads the *content* of the secret file.
        passwordFile = config.sops.secrets.keycloak_db_password.path;
      }
      {
        name = "miniflux";
        passwordFile = config.sops.secrets.miniflux_db_password.path;
      }
      {
        name = "hass";
        passwordFile = config.sops.secrets.hass_db_password.path;
      }
    ];

    ensureDatabases = [
      "keycloak"
      "miniflux"
      "hass"
    ];
  };
}