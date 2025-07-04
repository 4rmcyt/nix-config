{ config, pkgs, ... }:

{
  # SOPS secrets
  sops.secrets.keycloak_db_password = {
    owner = "root";
    group = "root";
    mode = "0400";
  };
  sops.secrets.keycloak_admin_password = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # Package the trusted device plugin as a derivation (like notthebee)
  keycloak_trusted_device_plugin = pkgs.stdenv.mkDerivation {
    name = "keycloak-spi-trusted-device";
    src = pkgs.fetchurl {
      url = "https://github.com/wouterh-dev/keycloak-spi-trusted-device/releases/download/v0.0.2/keycloak-spi-trusted-device-0.0.2.jar";
      sha256 = "e84f6e3f5b7ce4f33115b7080fb1671d91e00c629ed80ae7d97d8c1c9af62dcf";
    };
    installPhase = ''
      mkdir -p $out
      cp $src $out/
    '';
  };

  # Package your theme as a derivation (like notthebee)
  keycloak_theme = pkgs.stdenv.mkDerivation {
    name = "keycloak-theme";
    src = ./keycloak-theme;
    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };

  services.keycloak = {
    enable = true;
    initialAdminPassword = config.sops.secrets.keycloak_admin_password.path;
    database = {
      createLocally = false;
      host = "localhost";
      port = 5432;
      username = "keycloak";
      passwordFile = config.sops.secrets.keycloak_db_password.path;
    };
    themes = [ keycloak_theme ];
    plugins = [ keycloak_trusted_device_plugin ];
    settings = {
      hostname = "keycloak.labhome.work";
      http-host = "0.0.0.0";
      http-port = 8080;
      hostname-strict-https = false;
      proxy-headers = "xforwarded";
      db = "postgres";
      db-username = "keycloak";
      log-level = "INFO";
      log-console-output = "default";
      http-enabled = true;
      # Add any other settings you need
    };
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
}
