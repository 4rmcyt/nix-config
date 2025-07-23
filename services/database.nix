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

    ensureUsers = [
      {
        name = "keycloak";
        ensureDBOwnership = true;
      }
      {
        name = "miniflux";
        ensureDBOwnership = true;
      }
      {
        name = "hass";
        ensureDBOwnership = true;
      }
    ];

    ensureDatabases = [
      "keycloak"
      "miniflux"
      "hass"
    ];
  };
  systemd.services.postgresql-setup-passwords = {
  description = "Set initial PostgreSQL user passwords from sops";
  after = [ "postgresql.service" "sops.service" ];
  wants = [ "postgresql.service" "sops.service" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "oneshot";
    User = "postgres";
  };
  # This script now strips any trailing newlines from the secret files
  script = ''
    ${pkgs.postgresql_15}/bin/psql -c "ALTER USER keycloak WITH PASSWORD '$(tr -d '\\n' < ${config.sops.secrets.keycloak_db_password.path})';"
    ${pkgs.postgresql_15}/bin/psql -c "ALTER USER hass WITH PASSWORD '$(tr -d '\\n' < ${config.sops.secrets.hass_db_password.path})';"
    ${pkgs.postgresql_15}/bin/psql -c "ALTER USER miniflux WITH PASSWORD '$(tr -d '\\n' < ${config.sops.secrets.miniflux_db_password.path})';"
  '';
};
}