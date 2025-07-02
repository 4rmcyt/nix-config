{ config, pkgs, ... }:

{
  sops.secrets.keycloak_db_password = {
    owner = "keycloak";
    group = "keycloak";
  };

  services.keycloak = {
    enable = true;
    settings = {
      hostname = "keycloak.yourdomain.com";
      http-port = 8081;
      proxy = "edge";
    };
    
    database = {
      type = "postgresql";
      createLocally = true;
      passwordFile = config.sops.secrets.keycloak_db_password.path;
    };
  };

  # Enable PostgreSQL
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "keycloak" ];
    ensureUsers = [
      {
        name = "keycloak";
        ensureDBOwnership = true;
      }
    ];
  };
}