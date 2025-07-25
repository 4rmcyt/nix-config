{
  config,
  pkgs,
  lib,
  ...
}:

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

    # ensureUsers and ensureDatabases are removed from here to prevent
    # race conditions with our custom setup script. Our single service below
    # will handle all of these tasks idempotently.
  };

  # This single, idempotent service handles all initial database setup.
  # It creates users, sets passwords, and creates databases, preventing race conditions.
  systemd.services.postgresql-initial-setup = {
    description = "Initial PostgreSQL setup for users, passwords, and databases";

    # This service must run after postgresql and sops are ready.
    after = [
      "postgresql.service"
      "sops.service"
    ];
    requires = [
      "postgresql.service"
      "sops.service"
    ];

    # This ensures the service is run on boot.
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
    };

    # This script handles all setup tasks. It's designed to be safely
    # run on every system boot.
    script =
      let
        psql = "${pkgs.postgresql_15}/bin/psql";
      in
      ''
        set -e
        # 1. Create users and set their passwords in a single transaction.
        # The DO blocks create the roles only if they don't already exist.
        # The ALTER USER commands will then set/update the password.
        ${psql} -v ON_ERROR_STOP=1 <<-'EOSQL'
          -- For Keycloak
          DO $$
          BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'keycloak') THEN
              CREATE ROLE keycloak WITH LOGIN;
            END IF;
          END
          $$;
          ALTER USER keycloak WITH PASSWORD '${config.sops.secrets.keycloak_db_password.path}';

          -- For Home Assistant (hass)
          DO $$
          BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'hass') THEN
              CREATE ROLE hass WITH LOGIN;
            END IF;
          END
          $$;
          ALTER USER hass WITH PASSWORD '${config.sops.secrets.hass_db_password.path}';

          -- For Miniflux
          DO $$
          BEGIN
            IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'miniflux') THEN
              CREATE ROLE miniflux WITH LOGIN;
            END IF;
          END
          $$;
          ALTER USER miniflux WITH PASSWORD '${config.sops.secrets.miniflux_db_password.path}';
        EOSQL

        # 2. Create databases if they don't exist.
        # This logic is in shell functions for clarity.
        db_exists() {
          ${psql} -tA -d postgres -c "SELECT 1 FROM pg_database WHERE datname = '$1'" | grep -q 1
        }
        create_db_if_not_exists() {
          if ! db_exists "$1"; then
            ${psql} -d postgres -c "CREATE DATABASE $1 WITH OWNER $1;"
          fi
        }
        create_db_if_not_exists "keycloak"
        create_db_if_not_exists "hass"
        create_db_if_not_exists "miniflux"
        create_db_if_not_exists "paperless"
      '';
  };

  # Update the dependency for the keycloak service to wait for the new setup script.
  systemd.services.keycloak = {
    after = [ "postgresql-initial-setup.service" ];
    requires = [ "postgresql-initial-setup.service" ];
  };
}
