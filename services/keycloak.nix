{ config, pkgs, ... }:

{
  sops.secrets.keycloak_db_password = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets.keycloak_default_user = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets.keycloak_default_password = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  services.keycloak = {
    enable = true;
    settings = {
      hostname = "keycloak.example.com";
      http-host = "0.0.0.0"; # TODO: Fix it after reverse proxy will be ready
      http-port = 8080;
      hostname-strict-https = false;
      proxy-headers = "xforwarded";
      db = "postgres";
      db-username = "keycloak";
      db-password-file = config.sops.secrets.keycloak_db_password.path;
      log-level = "INFO";
      log-console-output = "default";
      http-enabled = true;
    };

    database = {
      createLocally = false;
      host = "localhost";
      port = 5432;
      username = "keycloak";
      passwordFile = config.sops.secrets.keycloak_db_password.path;
    };

    initialAdminUser = config.sops.secrets.keycloak_default_user.path;
    initialAdminPasswordFile = config.sops.secrets.keycloak_default_password.path;
  };


  networking.firewall.allowedTCPPorts = [ 8080 ];
}