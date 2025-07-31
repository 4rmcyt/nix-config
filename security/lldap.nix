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
      http_url = "https://example.com";
      http_host = "127.0.0.1";
      ldap_base_dn = "dc=labhome,dc=work";
      ldaps_options.enabled = true;
      database_url = "postgres://lldap:${config.sops.secrets.lldap_db_password.path}@/localhost/lldap"; 
    };
    initialAdminPasswordFile = config.sops.secrets.lldap_admin_password.path;
    jwtSecretFile = config.sops.secrets.lldap_jwt_secret.path;
  };
}