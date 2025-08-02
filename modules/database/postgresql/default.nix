{
  config,
  pkgs,
  lib,
  ...
}:
{ 
  # sops.secrets.postgres = {
  #   sopsFile = ../../../secrets/postgresql.yaml;
  #   key = "postgres_password";
  #   owner = config.users.users.postgresql.name;
  #   group = config.users.groups.postgresql.name;
  #   mode = "0400";
  # };
  # sops.secrets.miniflux = {
  #   sopsFile = ../../../secrets/postgresql.yaml;
  #   key = "miniflux_db_password";
  #   owner = config.users.users.postgresql.name;
  #   group = config.users.groups.postgresql.name;
  #   mode = "0400";
  # };
  # sops.secrets.paperless = {
  #   sopsFile = ../../../secrets/postgresql.yaml;
  #   key = "paperless_db_password";
  #   owner = config.users.users.postgresql.name;
  #   group = config.users.groups.postgresql.name;
  #   mode = "0400";
  # };
  # sops.secrets.hass = {
  #   sopsFile = ../../../secrets/postgresql.yaml;
  #   key = "hass_db_password";
  #   owner = config.users.users.postgresql.name;
  #   group = config.users.groups.postgresql.name;
  #   mode = "0400";
  # };
  # sops.secrets.authentik = {
  #   sopsFile = ../../../secrets/postgresql.yaml;
  #   key = "authentik_db_password";
  #   mode = "0400";
  # };
  # sops.secrets.grafana = {
  #   sopsFile = ../../../secrets/postgresql.yaml;
  #   key = "grafana_db_password";
  #   owner = config.users.users.postgresql.name;
  #   group = config.users.groups.postgresql.name;
  #   mode = "0400";
  # };
  # sops.secrets.vaultwarden = {
  #   sopsFile = ../../../secrets/postgresql.yaml;
  #   key = "vaultwarden_db_password";
  #   owner = config.users.users.postgresql.name;
  #   group = config.users.groups.postgresql.name;
  #   mode = "0400";
  # };

  users.users.postgresql = {
    isSystemUser = true;
    group = "postgresql";
  };
  users.groups.postgresql = { };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    dataDir = "/var/lib/postgresql/data";
    ensureDatabases = [
      "miniflux"
      "paperless"
      "hass"
      "authentik"
      "grafana"
      "vaultwarden"
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
    ];
    #TODO: Authentication settings
  };

  networking.firewall.allowedTCPPorts = [
    5432 # PostgreSQL
  ];

  # systemd.services.postgresql.postStart = ''
  #   $PSQL -tA <<'EOF'
  #     DO $$
  #     DECLARE pwdPostgresql TEXT;
  #     DECLARE pwdAuthentik TEXT;
  #     DECLARE pwdHass TEXT;
  #     DECLARE pwdGrafana TEXT;
  #     DECLARE pwdMiniflux TEXT;
  #     DECLARE pwdPaperless TEXT;
  #     DECLARE pwdVaultwarden TEXT;
  #     BEGIN
  #       pwdPostgresql := trim(both from replace(pg_read_file('${config.sops.secrets.postgres.path}'), E'\n', '''));
  #       pwdAuthentik := trim(both from replace(pg_read_file('${config.sops.secrets.authentik.path}'), E'\n', '''));
  #       pwdHass := trim(both from replace(pg_read_file('${config.sops.secrets.hass.path}'), E'\n', '''));
  #       pwdGrafana := trim(both from replace(pg_read_file('${config.sops.secrets.grafana.path}'), E'\n', '''));
  #       pwdPaperless := trim(both from replace(pg_read_file('${config.sops.secrets.paperless.path}'), E'\n', '''));
  #       pwdMiniflux := trim(both from replace(pg_read_file('${config.sops.secrets.miniflux.path}'), E'\n', '''));
  #       pwdVaultwarden := trim(both from replace(pg_read_file('${config.sops.secrets.vaultwarden.path}'), E'\n', '''));
  #       EXECUTE format('ALTER USER admin PASSWORD '''%s''';', pwdPostgresql);
  #       EXECUTE format('ALTER USER authentik PASSWORD '''%s''';', pwdAuthentik);
  #       EXECUTE format('ALTER USER hass PASSWORD '''%s''';', pwdHass);
  #       EXECUTE format('ALTER USER grafana PASSWORD '''%s''';', pwdGrafana);
  #       EXECUTE format('ALTER USER paperless PASSWORD '''%s''';', pwdPaperless);
  #       EXECUTE format('ALTER USER miniflux PASSWORD '''%s''';', pwdMiniflux);
  #       EXECUTE format('ALTER USER vaultwarden PASSWORD '''%s''';', pwdVaultwarden);
  #     END $$;
  #   EOF
  # '';
}
