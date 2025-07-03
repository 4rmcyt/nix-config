{ config, pkgs, ... }:

{
  sops.secrets.keycloak_db_password = {
    owner = "keycloak";
    group = "keycloak";
  };

  services.keycloak = {
    enable = true;
    
    settings = {
      hostname = "keycloak.labhome.work";
      http-host = "127.0.0.1";
      http-port = 8080;
      
      # Updated proxy settings (removed deprecated 'proxy' option)
      proxy-headers = "xforwarded";
      hostname-strict = false;
      hostname-strict-https = false;
      
      # Database configuration
      db = "postgres";
      db-username = "keycloak";
      db-password-file = config.sops.secrets.keycloak_db_password.path;
      
      # Logging
      log-level = "INFO";
      log-console-output = "default";
    };
    
    # Database creation is handled by database.nix
    database = {
      createLocally = false;
      host = "localhost";
      port = 5432;
      username = "keycloak";
      passwordFile = config.sops.secrets.keycloak_db_password.path;
    };
  };

  # Open firewall port
  networking.firewall.allowedTCPPorts = [ 8080 ];
}