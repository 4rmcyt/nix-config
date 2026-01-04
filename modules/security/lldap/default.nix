{config, ...}: let
  inherit (config.my.defaults) domain;
in {
  # Create lldap user first (before SOPS tries to set ownership)
  users.users.lldap = {
    isSystemUser = true;
    group = "lldap";
  };
  users.groups.lldap = {
    members = ["authelia"]; # Authelia needs to read LLDAP password
  };

  # SOPS secrets for LLDAP
  sops.secrets = {
    lldap_jwt_secret = {
      sopsFile = ../../../secrets/lldap.yaml;
      key = "jwt_secret";
      owner = "lldap";
      mode = "0400";
    };
    lldap_user_pass = {
      sopsFile = ../../../secrets/lldap.yaml;
      key = "user_pass";
      owner = "lldap";
      group = "lldap";
      mode = "0440"; # Group-readable so authelia can access
    };
  };

  services.lldap = {
    enable = true;
    silenceForceUserPassResetWarning = true;
    settings = {
      http_url = "https://lldap.${domain}";
      http_port = 17170;
      ldap_base_dn = "dc=labhome,dc=work";
      force_ldap_user_pass_reset = false;
      database_url = "postgres:///lldap?host=/run/postgresql";
    };
    environment = {
      LLDAP_JWT_SECRET_FILE = config.sops.secrets.lldap_jwt_secret.path;
      LLDAP_LDAP_USER_PASS_FILE = config.sops.secrets.lldap_user_pass.path;
    };
  };

  # Firewall configuration
  networking.firewall.allowedTCPPorts = [
    17170 # LLDAP web UI
    3890 # LDAP port
  ];
}
