{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    ensureDatabases = [
      "keycloak"
      "miniflux"
      "paperless"
      "hass"
    ];
    ensureUsers = [
      {
        name = "keycloak";
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
      {
        name = "hass";
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
      #type database  DBuser  auth-method optional_ident_map
      local sameuser  all     peer        map=superuser_map
      local all postgres ident map=superuser_map
      #type database DBuser origin-address auth-method
      host  sameuser  all     ::1/128   md5
      host  sameuser  all     127.0.0.1/32   md5
      # for podman only
      host sameuser all 10.88.0.0/16 md5
      # for tailscale network
      host sameuser all 100.75.0.0/10 md5
    '';

  };

  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    location = "/var/lib/postgresql/backup";
  };

  users.users.postgresql = {
    isSystemUser = true;
    group = "postgresql";
  };
  users.groups.postgresql = { };

}
