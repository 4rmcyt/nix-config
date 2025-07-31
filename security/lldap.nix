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
      http_url = "https://labhome.work";
      http_host = "127.0.0.1";
      ldap_base_dn = "dc=labhome,dc=work";
      ldaps_options.enabled = true;
      database_url = "postgres://lldap:${config.sops.secrets.lldap_db_password.path}?host=/run/postgresql";
      ldap_user_email = "4rmcyt@gmail.com"; 
    };
    environment = {
      LLDAP_ADMIN_PASSWORD = config.sops.secrets.lldap_admin_password.path;
      LLDAP_JWT_SECRET = config.sops.secrets.lldap_jwt_secret.path;
      LLDAP_LDAPS_OPTIONS__ENABLED = "true";
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