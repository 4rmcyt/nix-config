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
    
    # This script runs once to set the master password for the 'postgres' user.
    initialScript = pkgs.writeText "postgres-init-script" ''
      ALTER USER postgres WITH PASSWORD '${config.sops.placeholder."postgres_password"}';
    '';
    
    # This tells sops-nix to replace the placeholder above with the real password.
    sops.placeholder."postgres_password" = {
      path = config.sops.secrets.postgres_password.path;
      format = "unquoted";
    };

    ensureDatabases = [
      "keycloak"
      "nextcloud" 
      "miniflux"
      "hass"
    ];
    
    ensureUsers = [
      { name = "keycloak"; ensureDBOwnership = true; }
      { name = "nextcloud"; ensureDBOwnership = true; }
      { name = "miniflux"; ensureDBOwnership = true; }
      { name = "hass"; ensureDBOwnership = true; }
    ];
    
    authentication = pkgs.lib.mkOverride 10 ''
      local   all   all   scram-sha-256
      host    all   all   127.0.0.1/32   scram-sha-256
      host    all   all   ::1/128        scram-sha-256
    '';
  };

  # This service, which sets the other passwords, remains unchanged.
  # It will now be able to connect using the newly set postgres password.
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
        
        # This script now needs to provide the postgres password to connect
        PGPASSWORD=$(cat ${config.sops.secrets.postgres_password.path}) ${pkgs.postgresql_15}/bin/psql -U postgres -c "ALTER USER hass WITH PASSWORD '$(cat ${config.sops.secrets.hass_db_password.path})';"
        PGPASSWORD=$(cat ${config.sops.secrets.postgres_password.path}) ${pkgs.postgresql_15}/bin/psql -U postgres -c "ALTER USER miniflux WITH PASSWORD '$(cat ${config.sops.secrets.miniflux_db_password.path})';"
        PGPASSWORD=$(cat ${config.sops.secrets.postgres_password.path}) ${pkgs.postgresql_15}/bin/psql -U postgres -c "ALTER USER nextcloud WITH PASSWORD '$(cat ${config.sops.secrets.nextcloud_db_password.path})';"
        PGPASSWORD=$(cat ${config.sops.secrets.postgres_password.path}) ${pkgs.postgresql_15}/bin/psql -U postgres -c "ALTER USER keycloak WITH PASSWORD '$(cat ${config.sops.secrets.keycloak_db_password.path})';"
      '';
    };
  };
}
