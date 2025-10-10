{
  config,
  pkgs,
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
    linkwarden = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "linkwarden_db_password";
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
      "vaultwarden"
      "linkwarden"
    ];

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
  };

  # Set up user passwords after PostgreSQL is running
  systemd.services.postgresql-setup-users = {
    description = "Set up PostgreSQL user passwords";
    after = [ "postgresql.service" "sops-install-secrets.service" ];
    requires = [ "postgresql.service" "sops-install-secrets.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
      Group = "postgres";
    };
    script = ''
      ${pkgs.postgresql_16}/bin/psql -c "ALTER USER linkwarden WITH PASSWORD '$(cat ${config.sops.secrets.linkwarden.path})';"
      ${pkgs.postgresql_16}/bin/psql -c "ALTER USER miniflux WITH PASSWORD '$(cat ${config.sops.secrets.miniflux.path})';"
      ${pkgs.postgresql_16}/bin/psql -c "ALTER USER paperless WITH PASSWORD '$(cat ${config.sops.secrets.paperless.path})';"
      ${pkgs.postgresql_16}/bin/psql -c "ALTER USER hass WITH PASSWORD '$(cat ${config.sops.secrets.hass.path})';"
      ${pkgs.postgresql_16}/bin/psql -c "ALTER USER authentik WITH PASSWORD '$(cat ${config.sops.secrets.authentik.path})';"
      ${pkgs.postgresql_16}/bin/psql -c "ALTER USER grafana WITH PASSWORD '$(cat ${config.sops.secrets.grafana.path})';"
      ${pkgs.postgresql_16}/bin/psql -c "ALTER USER vaultwarden WITH PASSWORD '$(cat ${config.sops.secrets.vaultwarden.path})';"
    '';
  };
}