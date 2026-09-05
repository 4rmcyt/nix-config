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
      name = "atuin";
      secret = "atuin_db_password";
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
  ];
in {
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
    atuin_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "atuin_db_password";
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
  };

  users.users.postgres = {
    isSystemUser = true;
    group = "postgres";
  };
  users.groups.postgres = {};

  # No global TCP 5432 opening here on purpose: pg_hba below only trusts
  # loopback + the podman bridge (10.88.0.0/16) anyway, and that range is
  # already interface-scoped at the host level
  # (hosts/nixos/homeserver/default.nix: firewall.interfaces.podman0). A
  # blanket allowedTCPPorts opened the port on every interface (LAN/tailscale
  # included) for no functional gain, since pg_hba would refuse those source
  # IPs regardless — pure unnecessary attack surface (port scan/banner recon).

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql;

    ensureDatabases = [
      "miniflux"
      "hass"
      "grafana"
      "atuin"
      "bazarr"
      "radarr"
      "radarr-log"
      "sonarr"
      "sonarr-log"
      "prowlarr"
      "prowlarr-log"
      "dispatcharr"
      "kombayn"
    ];

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
        name = "atuin";
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
        # peer-auth only (local unix socket, no TCP/password) — see
        # modules/services/job-kombayn, not part of `dbUsers` above on purpose
        name = "kombayn";
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
      # Require password authentication for network connections (both IPv4 and IPv6)
      host  all all 127.0.0.1/32 scram-sha-256
      host  all all ::1/128      scram-sha-256
      host  all all ${config.my.network.subnets.podman} scram-sha-256
    '';
  };

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
      Restart = "on-failure";
      RestartSec = "10s";
    };
    script = ''
      # Refresh collation version to avoid mismatch errors after OS upgrades
      ${pkgs.postgresql}/bin/psql -c "ALTER DATABASE template1 REFRESH COLLATION VERSION;" || true
      ${pkgs.postgresql}/bin/psql -c "ALTER DATABASE postgres REFRESH COLLATION VERSION;" || true

      # Wait (bounded) for all secrets to be available
      ${lib.concatMapStringsSep "\n      " (user: ''
          for i in $(seq 1 30); do
            [ -f ${config.sops.secrets.${user.secret}.path} ] && break
            echo "Waiting for ${user.name} secret to be available..."
            sleep 1
          done
          if [ ! -f ${config.sops.secrets.${user.secret}.path} ]; then
            echo "${user.name} secret never appeared, giving up" >&2
            exit 1
          fi
        '')
        dbUsers}

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

      # PG15+ removed implicit CREATE on schema public — restore it for all app users
      ${lib.concatMapStringsSep "\n      " (user: ''
          ${pkgs.postgresql}/bin/psql -d "${user.name}" -c "GRANT ALL ON SCHEMA public TO ${user.name};" || true
        '')
        dbUsers}

      # kombayn: peer-auth only, not in dbUsers (no password to wait for), but
      # still needs the same PG15+ public-schema grant as everyone else
      ${pkgs.postgresql}/bin/psql -d "kombayn" -c "GRANT ALL ON SCHEMA public TO kombayn;" || true

      # Fix ownership and schema access for *-log databases (created by ensureDatabases, owned by postgres)
      for db_user in radarr sonarr prowlarr; do
        ${pkgs.postgresql}/bin/psql -c "ALTER DATABASE \"''${db_user}-log\" OWNER TO ''${db_user};" || true
        ${pkgs.postgresql}/bin/psql -d "''${db_user}-log" -c "GRANT ALL ON SCHEMA public TO ''${db_user};" || true
      done
    '';
  };
}
