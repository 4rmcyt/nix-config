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

    # Use ensureUsers to declaratively manage roles. This is idempotent and
    # guarantees the roles exist before we try to set their passwords.
    ensureUsers = [
      { name = "keycloak"; }
      { name = "hass"; }
      { name = "miniflux"; }
    ];

    # Use ensureDatabases to declaratively manage databases.
    # This should be a list of strings. The owner is automatically
    # set to a user with the same name as the database.
    ensureDatabases = [
      "keycloak"
      "hass"
      "miniflux"
    ];
  };

  # This systemd service runs after postgresql is up to set the passwords.
  # Because `ensureUsers` has already run, we know the roles will exist.
  systemd.services.postgresql-setup-passwords = {
    description = "Set initial PostgreSQL user passwords from sops";
    # This service must run after postgresql and sops are ready.
    after = [ "postgresql.service" "sops.service" ];
    requires = [ "postgresql.service" "sops.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      # This makes the script idempotent. If a user's password is
      # already set, the command will succeed without changes.
      ExecStart = ''
        ${pkgs.writeShellScript "set-postgres-passwords" ''
          set -e
          ${pkgs.postgresql_15}/bin/psql -c "ALTER USER keycloak WITH PASSWORD '$(cat ${config.sops.secrets.keycloak_db_password.path})';"
          ${pkgs.postgresql_15}/bin/psql -c "ALTER USER hass WITH PASSWORD '$(cat ${config.sops.secrets.hass_db_password.path})';"
          ${pkgs.postgresql_15}/bin/psql -c "ALTER USER miniflux WITH PASSWORD '$(cat ${config.sops.secrets.miniflux_db_password.path})';"
        ''}
      '';
    };
    # This ensures the service is run on boot.
    wantedBy = [ "multi-user.target" ];
  };
}
