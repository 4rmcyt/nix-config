{
  config,
  pkgs,
  lib,
  ...
}: {
  # PostgreSQL for Dify
  sops.secrets.dify_db_password_pg = {
    sopsFile = ../../../secrets/dify.yaml;
    key = "dify_db_password";
    owner = config.users.users.postgres.name;
    group = config.users.groups.postgres.name;
    mode = "0400";
  };

  users.users.postgres = {
    isSystemUser = true;
    group = "postgres";
  };
  users.groups.postgres = {};

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql; # Note: Ensure this matches the version in your logs (v17)
    ensureDatabases = [
      "dify"
      "dify_plugin"
    ];
    ensureUsers = [
      {
        name = "dify";
        ensureDBOwnership = true;
      }
    ];
    # FIXED: Use "*" to resolve the "Cannot assign requested address" race condition
    settings.listen_addresses = lib.mkForce "*";

    authentication = pkgs.lib.mkOverride 10 ''
      local all       all     peer
      host  all all 127.0.0.1/32 scram-sha-256
      host  all all 10.88.0.0/16 scram-sha-256
    '';
  };

  systemd.services.postgresql-dify-setup = {
    description = "Set up PostgreSQL for Dify";
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
            # Wait for PG socket to be ready
            until ${pkgs.postgresql}/bin/pg_isready; do
              sleep 1
            done

            PASS=$(cat ${config.sops.secrets.dify_db_password_pg.path} | tr -d '\n\r')

            # Use a heredoc for cleaner SQL execution
            ${pkgs.postgresql}/bin/psql <<EOF
              DO \$$
              BEGIN
                IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'dify') THEN
                  CREATE ROLE dify WITH LOGIN PASSWORD '$PASS' CREATEDB;
                ELSE
                  ALTER ROLE dify WITH PASSWORD '$PASS' CREATEDB;
                END IF;
              END
              \$$;
      EOF
            # Grant schema permissions
            ${pkgs.postgresql}/bin/psql -d dify -c "GRANT ALL ON SCHEMA public TO dify;" || true
            ${pkgs.postgresql}/bin/psql -d dify_plugin -c "GRANT ALL ON SCHEMA public TO dify;" || true
    '';
  };

  # Redis for Dify
  sops.secrets.dify_redis_password_svc = {
    sopsFile = ../../../secrets/dify.yaml;
    key = "dify_redis_password";
    owner = "redis";
    group = "redis";
    mode = "0440";
  };

  users.users.redis = {
    isSystemUser = true;
    group = "redis";
  };
  users.groups.redis = {};

  services.redis.servers.dify = {
    enable = true;
    bind = "0.0.0.0";
    port = 6379;
    requirePassFile = config.sops.secrets.dify_redis_password_svc.path;
    databases = 4;
    settings = {
      maxmemory = "512MB";
      maxmemory-policy = "allkeys-lru";
      appendonly = "yes";
      appendfsync = "everysec";
    };
  };

  networking.firewall.trustedInterfaces = ["podman0"];

  networking.firewall.allowedTCPPorts = [
    5432
    6379
  ];
}
