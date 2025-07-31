{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.lldap = {
    enable = true;
    settings = {
      http_url = "https://lldap.example.com";
      http_host = "127.0.0.1";
      ldap_base_dn = "dc=labhome,dc=work";
      ldaps_options.enabled = true;
      database_url = "postgresql:///lldap?host=/run/postgresql";
      ldap_user_email = "redacted@example.com"; 
    };
    environment = {
      LLDAP_JWT_SECRET_FILE = "/run/lldap/jwt_secret_file";
      LLDAP_LDAP_USER_PASS_FILE = "/run/lldap/lldap_user_password";
      LLDAP_LDAPS_OPTIONS__ENABLED = "true";
      LLDAP_LDAPS_OPTIONS__CERT_FILE = config.sops.secrets.lldap_cert.path;
      LLDAP_LDAPS_OPTIONS__KEY_FILE = config.sops.secrets.lldap_key.path;

    };
  };
  users.users.lldap = {
    isSystemUser = true;
    group = "lldap";
    extraGroups = [ "users" ];
  };
  users.groups.lldap = { };

  systemd.services.lldap = {
      requires = [ "postgresql.service" ];
      after = [ "postgresql.service" ];
  };
}