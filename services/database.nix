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

    initialScript = pkgs.writeText "initial-db-script" ''
      CREATE ROLE keycloak WITH LOGIN;
      CREATE DATABASE keycloak WITH OWNER keycloak;
      CREATE ROLE nextcloud WITH LOGIN;
      CREATE DATABASE nextcloud WITH OWNER nextcloud;
      CREATE ROLE miniflux WITH LOGIN;
      CREATE DATABASE miniflux WITH OWNER miniflux;
      CREATE ROLE hass WITH LOGIN;
      CREATE DATABASE hass WITH OWNER hass;
    '';
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
    script = ''
      ${pkgs.postgresql_15}/bin/psql -c "ALTER USER keycloak WITH PASSWORD '${config.sops.secrets.database_passwords.keycloak_db_password.path}';"
      ${pkgs.postgresql_15}/bin/psql -c "ALTER USER nextcloud WITH PASSWORD '${config.sops.secrets.database_passwords.nextcloud_db_password.path}';"
      ${pkgs.postgresql_15}/bin/psql -c "ALTER USER hass WITH PASSWORD '${config.sops.secrets.database_passwords.hass_db_password.path}';"
      ${pkgs.postgresql_15}/bin/psql -c "ALTER USER miniflux WITH PASSWORD '${config.sops.secrets.database_passwords.miniflux_db_password.path}';"
    '';
  };
}
