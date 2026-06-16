{
  config,
  pkgs,
  lib,
  ...
}: let
  # Database users for script generation
  dbUsers = [
    {
      name = "miniflux";
      secret = "miniflux_db_password";
    }
    {
      name = "hass";
      secret = "hass_db_password";
    }
    {
      name = "grafana";
      secret = "grafana_db_password";
    }
    {
      name = "vaultwarden";
      secret = "vaultwarden_db_password";
    }
    {
      name = "atuin";
      secret = "atuin_db_password";
    }
    {
      name = "authelia";
      secret = "authelia_db_password";
    }
    {
      name = "lldap";
      secret = "lldap_db_password";
    }
    {
      name = "bazarr";
      secret = "bazarr_db_password";
    }
    {
      name = "radarr";
      secret = "radarr_db_password";
    }
    {
      name = "sonarr";
      secret = "sonarr_db_password";
    }
    {
      name = "prowlarr";
      secret = "prowlarr_db_password";
    }
    {
      name = "dispatcharr";
      secret = "dispatcharr_db_password";
    }
    {
      name = "dify";
      secret = "dify_db_password";
    }
  ];
in {
  # Database secrets configuration
  sops.secrets = {
    miniflux_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "miniflux_db_password";
      owner = config.users.users.postgres.name;
      group = config.users.groups.postgres.name;
      mode = "0400";
    };
    hass_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "hass_db_password";
      owner = config.users.users.postgres.name;
      group = config.users.groups.postgres.name;
      mode = "0400";
    };
    grafana_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "grafana_db_password";
      owner = config.users.users.postgres.name;
      group = config.users.groups.postgres.name;
      mode = "0400";
    };
    vaultwarden_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "vaultwarden_db_password";
      owner = config.users.users.postgres.name;
      group = config.users.groups.postgres.name;
      mode = "0400";
    };
    atuin_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "atuin_db_password";
      owner = config.users.users.postgres.name;
      group = config.users.groups.postgres.name;
      mode = "0400";
    };
    authelia_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "authelia_db_password";
      owner = config.users.users.postgres.name;
      group = config.users.groups.postgres.name;
      mode = "0440"; # Group-readable so authelia user can access
    };
    lldap_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "lldap_db_password";
      owner = config.users.users.postgres.name;
      group = config.users.groups.postgres.name;
      mode = "0400";
    };
    bazarr_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "bazarr_db_password";
      owner = config.users.users.postgres.name;
      group = config.users.groups.bazarr.name;
      mode = "0440";
    };
    radarr_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "radarr_db_password";
      owner = config.users.users.postgres.name;
      group = config.users.groups.radarr.name;
      mode = "0440";
    };
    sonarr_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "sonarr_db_password";
      owner = config.users.users.postgres.name;
      group = config.users.groups.sonarr.name;
      mode = "0440";
    };
    prowlarr_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "prowlarr_db_password";
      owner = config.users.users.postgres.name;
      group = config.users.groups.prowlarr.name;
      mode = "0440";
    };
    dispatcharr_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "dispatcharr_db_password";
      owner = config.users.users.postgres.name;
      group = config.users.groups.postgres.name;
      mode = "0440";
    };
    dify_db_password = {
      sopsFile = ../../../secrets/dify.yaml;
      key = "dify_db_password";
      owner = config.users.users.postgres.name;
      group = config.users.groups.postgres.name;
      mode = "0400";
    };
  };

  users.users.postgres = {
    isSystemUser = true;
    group = "postgres";
  };
  users.groups.postgres = {};

  networking.firewall.allowedTCPPorts = [
    5432 # PostgreSQL
  ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql;

    # Automatically create databases for all app users
    ensureDatabases = [
      "miniflux"
      "hass"
      "grafana"
      "vaultwarden"
      "lldap"
      "atuin"
      "authelia"
      "bazarr"
      "radarr"
      "radarr-log"
      "sonarr"
      "sonarr-log"
      "prowlarr"
      "prowlarr-log"
      "dispatcharr"
      "dify"
      "dify_plugin"
    ];

    # Automatically create users with DB ownership
    ensureUsers = [
      {
        name = "miniflux";
        ensureDBOwnership = true;
      }
      {
        name = "hass";
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
        name = "atuin";
        ensureDBOwnership = true;
      }
      {
        name = "authelia";
        ensureDBOwnership = true;
      }
      {
        name = "lldap";
        ensureDBOwnership = true;
      }
      {
        name = "bazarr";
        ensureDBOwnership = true;
      }
      {
        name = "radarr";
        ensureDBOwnership = true;
      }
      {
        name = "sonarr";
        ensureDBOwnership = true;
      }
      {
        name = "prowlarr";
        ensureDBOwnership = true;
      }
      {
        name = "dispatcharr";
        ensureDBOwnership = true;
      }
      {
        name = "dify";
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

    settings.listen_addresses = lib.mkForce "*";

    authentication = pkgs.lib.mkOverride 10 ''
      # Use peer authentication for local socket connections (maps system users to DB users)
      local all       all     peer map=superuser_map
      # Trust hass user from microvm bridge (home-assistant VM, internal bridge only)
      host  hass hass 192.168.200.0/24 trust
      # Require password authentication for network connections (both IPv4 and IPv6)
      host  all all 127.0.0.1/32 scram-sha-256
      host  all all ::1/128      scram-sha-256
      host  all all 10.88.0.0/16 scram-sha-256
    '';
  };

  # Set up user passwords after PostgreSQL is running
  systemd.services.postgresql-setup-users = {
    description = "Set up PostgreSQL user passwords";
    after = ["postgresql.service"];
    requires = ["postgresql.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
      Group = "postgres";
    };
    script = ''
      # Refresh collation version to avoid mismatch errors after OS upgrades
      ${pkgs.postgresql}/bin/psql -c "ALTER DATABASE template1 REFRESH COLLATION VERSION;" || true
      ${pkgs.postgresql}/bin/psql -c "ALTER DATABASE postgres REFRESH COLLATION VERSION;" || true

      # Wait for all secrets to be available
      ${lib.concatMapStringsSep "\n      " (user: ''
          while [ ! -f ${config.sops.secrets.${user.secret}.path} ]; do
            echo "Waiting for ${user.name} secret to be available..."
            sleep 1
          done
        '')
        dbUsers}

      # Grant dify user full access to dify_plugin schema (plugin daemon connects as dify)
      ${pkgs.postgresql}/bin/psql -d dify_plugin -c "GRANT ALL ON SCHEMA public TO dify;" || true

      # Set passwords for all database users, grant CREATEDB privilege, and ensure database exists
      ${lib.concatMapStringsSep "\n      " (user: ''
          # ${user.name}
          if ${pkgs.postgresql}/bin/psql -c "SELECT 1 FROM pg_roles WHERE rolname='${user.name}'" | grep -q 1; then
            echo "Updating user ${user.name}..."
            ${pkgs.postgresql}/bin/psql -c "ALTER USER ${user.name} WITH PASSWORD '$(cat ${
            config.sops.secrets.${user.secret}.path
          } | tr -d '\n\r')' CREATEDB;"
          else
            echo "Creating user ${user.name}..."
            ${pkgs.postgresql}/bin/psql -c "CREATE USER ${user.name} WITH PASSWORD '$(cat ${
            config.sops.secrets.${user.secret}.path
          } | tr -d '\n\r')' CREATEDB;"
          fi
          ${pkgs.postgresql}/bin/psql -c "SELECT 'CREATE DATABASE ${user.name} OWNER ${user.name}' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname='${user.name}')" \
            | grep -q "CREATE DATABASE" \
            && { echo "Creating database ${user.name}..."; ${pkgs.postgresql}/bin/psql -c "CREATE DATABASE ${user.name} OWNER ${user.name};"; } \
            || true
        '')
        dbUsers}

    '';
  };
}
