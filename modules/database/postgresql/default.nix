{
  config,
  pkgs,
  lib,
  ...
}: let
  # Database users and their configurations
  dbUsers = ["postgres" "miniflux" "paperless" "hass" "authentik" "grafana" "vaultwarden" "linkwarden" "flare" "atuin"];

  # Generate SOPS secret configuration for a database user
  mkDbSecret = user: {
    sopsFile = ../../../secrets/postgresql.yaml;
    key = "${user}_${
      if user == "postgres"
      then "password"
      else "db_password"
    }";
    owner = config.users.users.postgresql.name;
    group = config.users.groups.postgresql.name;
    mode = "0400";
  };
in {
  # Generate all database secrets dynamically
  sops.secrets = lib.genAttrs dbUsers mkDbSecret;

  users.users.postgresql = {
    isSystemUser = true;
    group = "postgresql";
  };
  users.groups.postgresql = {};

  networking.firewall.allowedTCPPorts = [
    5432 # PostgreSQL
  ];

  services.postgresql = let
    appDatabases = lib.filter (u: u != "postgres") dbUsers;
  in {
    enable = true;
    package = pkgs.postgresql;

    # Automatically create databases for all app users
    ensureDatabases = appDatabases;

    # Automatically create users with DB ownership
    ensureUsers =
      map (name: {
        inherit name;
        ensureDBOwnership = true;
      })
      appDatabases;

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
        while [ ! -f ${config.sops.secrets.${user}.path} ]; do
          echo "Waiting for ${user} secret to be available..."
          sleep 1
        done
      '') (lib.filter (u: u != "postgres") dbUsers)}

      # Set passwords for all database users, grant CREATEDB privilege, and ensure database exists
      ${lib.concatMapStringsSep "\n      " (user: ''
        # Set password and grant CREATEDB privilege
        ${pkgs.postgresql}/bin/psql -c "ALTER USER ${user} WITH PASSWORD '$(cat ${config.sops.secrets.${user}.path} | tr -d '\n\r')' CREATEDB;"

        # Create database if it doesn't exist
        if ! ${pkgs.postgresql}/bin/psql -lqt | cut -d \| -f 1 | grep -qw ${user}; then
          echo "Creating database ${user}..."
          ${pkgs.postgresql}/bin/psql -c "CREATE DATABASE ${user} OWNER ${user};"
        fi
      '') (lib.filter (u: u != "postgres") dbUsers)}
    '';
  };
}
