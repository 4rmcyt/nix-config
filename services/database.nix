{ config, pkgs, ... }:

{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    
    settings = {
      max_connections = 100;
      shared_buffers = "256MB";
      effective_cache_size = "1GB";
      maintenance_work_mem = "64MB";
    };
    
    initialScript = pkgs.writeText "init-postgres.sql" ''
      -- Create databases
      CREATE DATABASE IF NOT EXISTS keycloak;
      CREATE DATABASE IF NOT EXISTS nextcloud;
      CREATE DATABASE IF NOT EXISTS miniflux;
      CREATE DATABASE IF NOT EXISTS hass;
      
      -- Create users
      CREATE USER IF NOT EXISTS keycloak WITH PASSWORD 'temp_password';
      CREATE USER IF NOT EXISTS nextcloud WITH PASSWORD 'temp_password';
      CREATE USER IF NOT EXISTS miniflux WITH PASSWORD 'temp_password';
      CREATE USER IF NOT EXISTS hass WITH PASSWORD 'temp_password';
      
      -- Grant privileges
      GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
      GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;
      GRANT ALL PRIVILEGES ON DATABASE miniflux TO miniflux;
      GRANT ALL PRIVILEGES ON DATABASE hass TO hass;
      
      -- Note: Passwords will be updated via secrets after first boot
    '';
    
    ensureDatabases = [
      "keycloak"
      "nextcloud" 
      "miniflux"
      "hass"
    ];
    
    ensureUsers = [
      {
        name = "keycloak";
        ensureDBOwnership = true;
      }
      {
        name = "nextcloud";
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
    
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
  };

  # Set up database passwords after PostgreSQL is running
  systemd.services.postgresql-setup-passwords = {
    description = "Set up PostgreSQL passwords";
    after = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "setup-postgres-passwords" ''
        # Wait for PostgreSQL to be ready
        until ${pkgs.postgresql_15}/bin/pg_isready -h localhost; do
          sleep 1
        done
        
        # Set passwords from secrets
        ${pkgs.postgresql_15}/bin/psql -U postgres -c "ALTER USER hass WITH PASSWORD '$(cat ${config.sops.secrets.hass_postgres_password.path})';"
      '';
    };
  };
}