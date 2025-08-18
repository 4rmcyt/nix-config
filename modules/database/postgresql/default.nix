{
  config,
  pkgs,
  lib,
  ...
}:
{
  sops.secrets = {
    postgres = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "postgres_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
    miniflux = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "miniflux_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
    paperless = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "paperless_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
    hass = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "hass_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
    authentik = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "authentik_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
    grafana = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "grafana_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
    vaultwarden = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "vaultwarden_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
  };
  users.users.postgresql = {
    isSystemUser = true;
    group = "postgresql";
  };
  users.groups.postgresql = { };

  networking.firewall.allowedTCPPorts = [
    5432 # PostgreSQL
  ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    ensureDatabases = [
      "miniflux"
      "paperless"
      "hass"
      "authentik"
      "grafana"
      # "vaultwarden"
      "linkwarden" 
    ];

    #   settings = {
    #   # Connection limits
    #   max_connections = 50;
    #   shared_buffers = "256MB";
    #   effective_cache_size = "1GB";

    #   # Security settings
    #   ssl = true;
    #   ssl_cert_file = "/var/lib/postgresql/server.crt";
    #   ssl_key_file = "/var/lib/postgresql/server.key";

    #   # Logging for security
    #   log_statement = "mod";  # Log modifications
    #   log_min_duration_statement = 1000;  # Log slow queries
    #   log_connections = true;
    #   log_disconnections = true;
    #   log_checkpoints = true;

    #   # Authentication
    #   password_encryption = "scram-sha-256";

    #   # Performance and security
    #   shared_preload_libraries = [ "pg_stat_statements" ];
    #   track_activity_query_size = 2048;
    # };

    # # Host-based authentication
    # authentication = pkgs.lib.mkOverride 10 ''
    #   # Local connections
    #   local all all peer

    #   # Network connections (restrict to local network)
    #   host all all 127.0.0.1/32 scram-sha-256
    #   host all all ::1/128 scram-sha-256
    #   host all all 192.168.1.0/24 scram-sha-256
    # '';
    ensureUsers = [
      {
        name = "miniflux";
        ensureDBOwnership = true;
      }
      {
        name = "paperless";
        ensureDBOwnership = true;
      }
      {
        name = "hass";
        ensureDBOwnership = true;
      }
      {
        name = "authentik";
        ensureDBOwnership = true;
      }
      {
        name = "grafana";
        ensureDBOwnership = true;
      }
      {
        name = "vaultwarden";
        ensureDBOwnership = true;
      }
      {
        name = "linkwarden";
        ensureDBOwnership = true;
      }
    ];

    identMap = ''
      # ArbitraryMapName systemUser DBUser
         superuser_map      root      postgres
         superuser_map      postgres  postgres
         # Let other names login as themselves
         superuser_map      /^(.*)$   \1
    '';

    authentication = pkgs.lib.mkOverride 10 ''
      # Allow local users to connect via sockets without a password
      local all       all     trust
      # Require a password for network connections from localhost (both IPv4 and IPv6)
      host  all all 127.0.0.1/32 scram-sha-256
      host  all all ::1/128      scram-sha-256
    '';

    initialScript = pkgs.writeText "postgresql-init-passwords" ''
    ALTER ROLE miniflux WITH LOGIN PASSWORD '${config.sops.secrets.miniflux.path}';
    ALTER ROLE paperless WITH LOGIN PASSWORD '${config.sops.secrets.paperless.path}';
    ALTER ROLE hass WITH LOGIN PASSWORD '${config.sops.secrets.hass.path}';
    ALTER ROLE authentik WITH LOGIN PASSWORD '${config.sops.secrets.authentik.path}';
    ALTER ROLE grafana WITH LOGIN PASSWORD '${config.sops.secrets.grafana.path}';
    ALTER ROLE vaultwarden WITH LOGIN PASSWORD '${config.sops.secrets.vaultwarden.path}';
  '';
  };

  # systemd.services.postgresql.serviceConfig = {
  #   # Resource limits
  #   MemoryMax = "2G";
  #   CPUQuota = "150%";

  #   # Security hardening
  #   NoNewPrivileges = true;
  #   PrivateTmp = true;
  #   ProtectHome = true;
  #   ProtectSystem = "strict";
  #   ReadWritePaths = [ "/var/lib/postgresql" ];

  #   # Network restrictions
  #   RestrictAddressFamilies = [
  #     "AF_INET"
  #     "AF_INET6"
  #     "AF_UNIX"
  #   ];
  # };
}
