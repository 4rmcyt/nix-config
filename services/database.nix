{ config, pkgs, ... }:

{
  # Centralized PostgreSQL configuration for all services
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    
    # Configure PostgreSQL settings
    settings = {
      shared_preload_libraries = "pg_stat_statements";
      log_statement = "all";
      log_destination = "stderr";
      logging_collector = true;
      log_directory = "/var/log/postgresql";
      log_filename = "postgresql-%Y-%m-%d.log";
      log_rotation_age = "1d";
      log_rotation_size = "100MB";
      max_connections = 100;
      shared_buffers = "256MB";
      effective_cache_size = "1GB";
      maintenance_work_mem = "64MB";
      checkpoint_completion_target = 0.9;
      wal_buffers = "16MB";
      default_statistics_target = 100;
      random_page_cost = 1.1;
      effective_io_concurrency = 200;
    };
    
    # Database initialization
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
    
    # Enable automatic vacuuming
    enableTCPIP = true;
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
  };

  # Create backup script using systemd timer
  systemd.services.postgresql-backup = {
    description = "PostgreSQL backup service";
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      Group = "postgres";
      ExecStart = pkgs.writeShellScript "postgres-backup" ''
        #!/bin/sh
        BACKUP_DIR="/var/backup/postgresql"
        DATE=$(date +%Y%m%d_%H%M%S)
        
        # Create backup directory
        mkdir -p $BACKUP_DIR
        
        # Backup each database
        for db in keycloak nextcloud miniflux hass; do
          ${pkgs.postgresql_15}/bin/pg_dump -h localhost -U postgres $db > $BACKUP_DIR/$db-$DATE.sql
        done
        
        # Keep only last 7 days of backups
        find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
      '';
    };
  };

  # Run backup daily at 2 AM
  systemd.timers.postgresql-backup = {
    description = "PostgreSQL backup timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "15min";
    };
  };

  # Create backup directory
  systemd.tmpfiles.rules = [
    "d /var/backup 0755 postgres postgres -"
    "d /var/backup/postgresql 0755 postgres postgres -"
  ];

  # Ensure PostgreSQL is started before dependent services
  systemd.services.postgresql.wantedBy = [ "multi-user.target" ];
}
