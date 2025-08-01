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
      "miniflux"
      "paperless"
      "hass"
      "authentik"
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
    ];
    #TODO: Authentication settings
  };

  networking.firewall.allowedTCPPorts = [
    5432 # PostgreSQL
  ];
  
  users.users.postgresql = {
    isSystemUser = true;
    group = "postgresql";
  };
  users.groups.postgresql = { };

}
