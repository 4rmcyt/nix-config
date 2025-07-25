{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
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

    # You can likely remove identMap unless you have specific needs for it.
     authentication = pkgs.lib.mkOverride 10 ''
        #...
        #type database DBuser origin-address auth-method
        local all       all     trust
        # ipv4
        host  all      all     127.0.0.1/32   trust
        # ipv6
        host all       all     ::1/128        trust
    '';
  };
}
