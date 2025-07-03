{ config, pkgs, ... }:

{
  sops.secrets.keycloak_db_password = {
    owner = "keycloak";
    group = "keycloak";
  };

  services.keycloak = {
    enable = true;
    settings = {
      hostname = "keycloak.example.com";
      http-port = 8080;
      proxy = "edge";
    };
    
    database = {
      type = "postgresql";
      createLocally = false;  # Database managed centrally
      host = "localhost";
      name = "keycloak";
      username = "keycloak";
      passwordFile = config.sops.secrets.keycloak_db_password.path;
    };
  };

  # Remove PostgreSQL configuration - handled by database.nix
}