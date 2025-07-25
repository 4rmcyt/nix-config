{
  config,
  pkgs,
  lib,
  ...
}:

# {
#   services.postgresql = {
#     enable = true;
#     package = pkgs.postgresql_15;
#     ensureDatabases = [ "keycloak" "miniflux" "paperless" "hass" ];
 
#     identMap = ''
#       # ArbitraryMapName systemUser DBUser
#         superuser_map      root      postgres
#         superuser_map      postgres  postgres
#       # Let other names login as themselves
#         superuser_map      /^(.*)$   \1
#     '';
#     initialScript = pkgs.writeText "initScript" ''
#       CREATE ROLE keycloak WITH LOGIN 'keycloak' PASSWORD '${config.sops.secrets.keycloak_db_password.path}' CREATEDB;
#       CREATE DATABASE keycloak;
#       GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;

#       CREATE ROLE miniflux WITH LOGIN 'miniflux' PASSWORD '${config.sops.secrets.miniflux_db_password.path}' CREATEDB;
#       CREATE DATABASE miniflux;
#       GRANT ALL PRIVILEGES ON DATABASE miniflux TO miniflux;

#       CREATE ROLE paperless WITH LOGIN 'paperless' PASSWORD '${config.sops.secrets.paperless_db_password.path}' CREATEDB;
#       CREATE DATABASE paperless;
#       GRANT ALL PRIVILEGES ON DATABASE paperless TO paperless;
#     '';
#   };
# }

services.postgresql = {
  enable = true;
  package = pkgs.postgresql_15;
  ensureDatabases = [ "keycloak" "miniflux" "paperless" "hass" ];
  
  ensureUsers = [
    {
      name = "keycloak";
      # This correctly uses the content of the secret file for the password
      passwordFile = config.sops.secrets.keycloak_db_password.path;
    }
    {
      name = "miniflux";
      passwordFile = config.sops.secrets.miniflux_db_password.path;
    }
    {
      name = "paperless";
      # Assuming you have this secret defined in sops.nix
      passwordFile = config.sops.secrets.paperless_db_password.path;
    }
  ];

  # You can likely remove identMap unless you have specific needs for it.
    identMap = ''
      # ArbitraryMapName systemUser DBUser
        superuser_map      root      postgres
        superuser_map      postgres  postgres
      # Let other names login as themselves
        superuser_map      /^(.*)$   \1
    '';
}

