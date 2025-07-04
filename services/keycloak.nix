{ config, pkgs, ... }:

{
  sops.secrets.keycloak_db_password = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  services.keycloak = {
    enable = true;
    settings = {
      http.enabled = true;
      hostname = "keycloak.example.com";
      http-host = "0.0.0.0";
      http-port = 8080;
      
      # Fix HTTPS issue - disable HTTPS requirement for development
      hostname-strict-https = false;
      proxy-headers = "xforwarded";
      
      # Database configuration
      db = "postgres";
      db-username = "keycloak";
      db-password-file = config.sops.secrets.keycloak_db_password.path;

      # Logging
      log-level = "INFO";
      log-console-output = "default";
    };

    database = {
      createLocally = false;
      host = "localhost";
      port = 5432;
      username = "keycloak";
      passwordFile = config.sops.secrets.keycloak_db_password.path;
    };
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
}
