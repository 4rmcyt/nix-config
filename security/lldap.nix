{
  pkgs,
  lib,
  config,
  ...
}:
{
  services.lldap = {
    enable = true;
    package = pkgs.lldap;
    settings = {
      http_host = "localhost";
      http_url = "https://example.com";
      ldap_base_dn = "dc=labhome,dc=work";
      database_url = "postgres://lldap:${config.sops.secrets.lldap.path}@/localhost/lldap";
      verbose = false;
    };
    environment = {
      LLDAP_LDAP_USER_PASS_FILE = config.sops.secrets.lldap_user_pass.path;
      LLDAP_JWT_SECRET_FILE = config.sops.secrets.lldap_jwt_secret.path;
      LLDAP_LDAPS_OPTIONS__ENABLED = "true";
    };
  };

  users.users.lldap = {
    name = "lldap";
    group = "lldap";
    isSystemUser = true;
  };

  users.groups.lldap = { };

  # # setup the backup
  # my.backups.services.lldap = {
  #   paths = ["/var/lib/lldap/" "/var/lib/private/lldap"];
  # };
}
