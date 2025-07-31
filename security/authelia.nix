{ config, lib, ... }: {
  services = {
    redis.servers.authelia.enable = true;
    authelia.instances.rucaslab = {
      enable = true;
      secrets = {
        jwtSecretFile = config.age.secrets.authelia_jwt_secret.path;
        storageEncryptionKeyFile =
          config.age.secrets.authelia_storage_encryption_key.path;
        sessionSecretFile = config.age.secrets.authelia_session_secret.path;
      };
      environmentVariables = {
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE =
          config.age.secrets.authelia_authentication_backend_ldap_password.path;
        AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE =
          config.age.secrets.authelia_notifier_smtp_password.path;
      };
      settings = {
        theme = "auto";
        default_2fa_method = "totp";
        totp.issuer = "authelia.com";
        # NOTE:
        # https://github.com/lldap/lldap/blob/main/example_configs/authelia_config.yml
        authentication_backend = {
          password_reset.disable = false;
          refresh_interval = "1m";
          ldap = {
            implementation = "custom";
            address = "ldap://localhost:3890";
            timeout = "5s";
            start_tls = false;
            base_dn = "dc=labhome,dc=work";
            users_filter =
              "(&({username_attribute}={input})(objectClass=person))";
            additional_groups_dn = "ou=groups";
            groups_filter = "(member={dn})";
            user = "uid=authelia,ou=people,dc=labhome,dc=work";
            attributes = {
              display_name = "displayName";
              group_name = "cn";
              mail = "mail";
              username = "uid";
            };
          };
        };
        log.level = "info";
        # notifier.filesystem.filename =
        #  "/var/lib/authelia-rucaslab/notification.txt";
        notifier = {
          disable_startup_check = true;
          smtp = {
            address = "smtp://heracles.mxrouting.net:587";
            username = "bot";
            sender = "bot <bot@example.com>";
          };
        };
        access_control = {
          default_policy = "deny";
          # We want this rule to be low priority so it doesn't override the others
          rules = lib.mkAfter [{
            domain = "*.example.com";
            policy = "one_factor";
          }];
        };
        storage.postgres = {
          address = "unix:///run/postgresql";
          database = "authelia-rucaslab";
          username = "authelia-rucaslab";
          password = "authelia-rucaslab";
        };
        session = {
          redis = { host = "/var/run/redis-authelia/redis.sock"; };
          cookies = [{
            domain = "example.com";
            authelia_url = "https://auth.example.com";
            inactivity = "1M";
            expiration = "3M";
            remember_me = "1M";
          }];
        };
      };
    };


  };

  users.users.authelia-rucaslab.extraGroups = [ "redis-authelia" ];

  systemd.services.authelia-rucaslab = let
    dependencies =
      [ "lldap.service" "postgresql.service" "redis-authelia.service" ];

  in {
    # Authelia requires LLDAP, PostgreSQL, and Redis to be running
    after = dependencies;
    requires = dependencies;
  };
}