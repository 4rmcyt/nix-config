{
  config,
  pkgs,
  lib,
  ...
}: let
  # Database users for script generation
  dbUsers = [
    {name = "miniflux"; secret = "miniflux";}
    {name = "paperless"; secret = "paperless";}
    {name = "hass"; secret = "hass";}
    {name = "authentik"; secret = "authentik";}
    {name = "grafana"; secret = "grafana";}
    {name = "vaultwarden"; secret = "vaultwarden";}
    {name = "linkwarden"; secret = "linkwarden";}
    {name = "flare"; secret = "flare";}
    {name = "atuin"; secret = "atuin_db_password";}
  ];
in {
  # Database secrets configuration
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
    flare = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "flare_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
  };

  users.users.postgresql = {
    isSystemUser = true;
    group = "postgresql";
  };
  users.groups.postgresql = {};

  networking.firewall.allowedTCPPorts = [
    5432 # PostgreSQL
  ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql;

    # Automatically create databases for all app users
    ensureDatabases = ["miniflux" "paperless" "hass" "authentik" "grafana" "vaultwarden" "linkwarden" "flare" "atuin"];

    # Automatically create users with DB ownership
    ensureUsers = [
      {name = "miniflux"; ensureDBOwnership = true;}
      {name = "paperless"; ensureDBOwnership = true;}
      {name = "hass"; ensureDBOwnership = true;}
      {name = "authentik"; ensureDBOwnership = true;}
      {name = "grafana"; ensureDBOwnership = true;}
      {name = "vaultwarden"; ensureDBOwnership = true;}
      {name = "linkwarden"; ensureDBOwnership = true;}
      {name = "flare"; ensureDBOwnership = true;}
      {name = "atuin"; ensureDBOwnership = true;}
    ];

    identMap = ''
      # ArbitraryMapName systemUser DBUser
         superuser_map      root      postgres
         superuser_map      postgres  postgres
         # Let other names login as themselves
         superuser_map      /^(.*)$   \1
    '';

    authentication = pkgs.lib.mkOverride 10 ''
      # Use peer authentication for local socket connections (maps system users to DB users)
      local all       all     peer map=superuser_map
      # Require password authentication for network connections (both IPv4 and IPv6)
      host  all all 127.0.0.1/32 scram-sha-256
      host  all all ::1/128      scram-sha-256
      host  all all ${config.virtualisation.podman.defaultNetwork.settings.subnet} scram-sha-256
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
      # Wait for all secrets to be available
      ${lib.concatMapStringsSep "\n      " (user: ''
        while [ ! -f ${config.sops.secrets.${user.secret}.path} ]; do
          echo "Waiting for ${user.name} secret to be available..."
          sleep 1
        done
      '') dbUsers}

      # Set passwords for all database users, grant CREATEDB privilege, and ensure database exists
      ${lib.concatMapStringsSep "\n      " (user: ''
        # ${user.name}
        ${pkgs.postgresql}/bin/psql -c "ALTER USER ${user.name} WITH PASSWORD '$(cat ${config.sops.secrets.${user.secret}.path} | tr -d '\n\r')' CREATEDB;"
        if ! ${pkgs.postgresql}/bin/psql -lqt | cut -d \| -f 1 | grep -qw ${user.name}; then
          echo "Creating database ${user.name}..."
          ${pkgs.postgresql}/bin/psql -c "CREATE DATABASE ${user.name} OWNER ${user.name};"
        fi
      '') dbUsers}
    '';
  };
}
