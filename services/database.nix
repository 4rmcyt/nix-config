{ config, pkgs, ... }:

{
  # Centralized PostgreSQL configuration for all services
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    
    # Configure all databases in one place
    ensureDatabases = [
      "keycloak"
      "nextcloud" 
      "miniflux"
      "paperless"
    ];
    
    # Configure all users in one place
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
        name = "paperless";
        ensureDBOwnership = true;
      }
    ];
    
    # Performance settings for server
    settings = {
      shared_buffers = "256MB";
      effective_cache_size = "1GB";
      maintenance_work_mem = "64MB";
      checkpoint_completion_target = 0.9;
      wal_buffers = "16MB";
      default_statistics_target = 100;
      random_page_cost = 1.1;
      effective_io_concurrency = 200;
    };
    
    # Enable automatic backups
    backup = {
      enable = true;
      startAt = "03:00";  # 3 AM daily
      location = "/var/backup/postgresql";
      databases = [ "keycloak" "nextcloud" "miniflux" "paperless" ];
    };
  };

  # Create backup directory
  systemd.tmpfiles.rules = [
    "d /var/backup 0750 postgres postgres -"
    "d /var/backup/postgresql 0750 postgres postgres -"
  ];
}