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
    #TODO: Authentication settings
  };

  users.users.postgresql = {
    isSystemUser = true;
    group = "postgresql";
  };
  users.groups.postgresql = { };

}
