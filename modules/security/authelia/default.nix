{config, ...}: let
  authelia = config.services.authelia.instances.main;
  redis = config.services.redis.servers.homeserver;
  port = 9000;
  autheliaUrl = "http://${authelia.settings.server.address}";
  inherit (config.my.defaults) domain user;
in {
  # SOPS secrets for Authelia
  sops.secrets = {
    authelia_jwt_secret = {
      sopsFile = ../../../secrets/authelia/jwt_secret;
      format = "binary";
      mode = "0400";
    };
    authelia_hmac_secret = {
      sopsFile = ../../../secrets/authelia/hmac_secret;
      format = "binary";
      mode = "0400";
    };
    authelia_issuer_priv_key = {
      sopsFile = ../../../secrets/authelia/issuer_priv_key.pem;
      format = "binary";
      mode = "0400";
    };
    authelia_session_secret = {
      sopsFile = ../../../secrets/authelia/session_secret;
      format = "binary";
      mode = "0400";
    };
    authelia_storage_encryption_key = {
      sopsFile = ../../../secrets/authelia/storage_encryption_key;
      format = "binary";
      mode = "0400";
    };
    ldap_password = {
      sopsFile = ../../../secrets/authelia/ldap_password;
      format = "binary";
      mode = "0400";
    };
  };

  environment.systemPackages = [config.services.authelia.instances.main.package];

  users.users."${user}".extraGroups = ["authelia"];
  users.users."${authelia.user}".extraGroups = ["redis"];

  # Nginx reverse proxy configuration for Authelia
  services.nginx.virtualHosts."auth.${domain}" = {
    forceSSL = true;
    sslCertificate = config.my.security.ssl.certPath;
    sslCertificateKey = config.my.security.ssl.keyPath;
    locations."/" = {
      proxyPass = autheliaUrl;
      proxyWebsockets = true;
    };
  };

  # Authelia service configuration
  services.authelia.instances.main = {
    enable = true;
    secrets = {
      jwtSecretFile = config.sops.secrets.authelia_jwt_secret.path;
      oidcHmacSecretFile = config.sops.secrets.authelia_hmac_secret.path;
      oidcIssuerPrivateKeyFile = config.sops.secrets.authelia_issuer_priv_key.path;
      sessionSecretFile = config.sops.secrets.authelia_session_secret.path;
      storageEncryptionKeyFile = config.sops.secrets.authelia_storage_encryption_key.path;
    };
    environmentVariables = {
      AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = config.sops.secrets.ldap_password.path;
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.sops.secrets.msmtp_gmail_password.path;
      AUTHELIA_STORAGE_POSTGRES_PASSWORD_FILE = config.sops.secrets.authelia_db_password.path;
      AUTHELIA_SESSION_REDIS_PASSWORD_FILE = config.sops.secrets.redis-oauth2-proxy-password.path;
    };
    settings = {
      theme = "dark";
      default_2fa_method = "totp";
      server.address = "localhost:${toString port}";
      log.level = "info";
      totp.issuer = "authelia.com";
      session = {
        cookies = [
          {
            inherit domain;
            authelia_url = "https://auth.${domain}";
            default_redirection_url = "https://${domain}";
          }
        ];
        redis = {
          host = redis.unixSocket;
          port = 0;
          database_index = 3; # Use database 3 for Authelia (0-2 are used by other services)
        };
      };
      regulation = {
        max_retries = 3;
        find_time = 120;
        ban_time = 300;
      };
      authentication_backend = {
        password_reset.disable = false;
        refresh_interval = "1m";
        ldap = {
          implementation = "custom";
          address = "ldap://localhost:3890";
          timeout = "5m";
          start_tls = false;
          base_dn = "dc=longerhv,dc=xyz";
          additional_users_dn = "ou=people";
          users_filter = "(&({username_attribute}={input})(objectClass=person))";
          additional_groups_dn = "ou=groups";
          groups_filter = "(member={dn})";
          user = "uid=admin,ou=people,dc=longerhv,dc=xyz";
          attributes = {
            display_name = "displayName";
            group_name = "cn";
            mail = "mail";
            username = "uid";
          };
        };
      };
      access_control = {
        default_policy = "deny";
        networks = [
          {
            name = "localhost";
            networks = ["127.0.0.1/32"];
          }
          {
            name = "internal";
            networks = config.my.network.subnets.private;
          }
        ];
        rules = [
          {
            domain = "*.${domain}";
            policy = "bypass";
            networks = "localhost";
          }
          {
            domain = "*.${domain}";
            policy = "one_factor";
            networks = "internal";
            subject = ["group:admin"];
          }
        ];
      };
      storage = {
        postgres = {
          address = "unix:///run/postgresql";
          database = "authelia";
          username = "authelia";
        };
      };
      notifier = {
        disable_startup_check = true;
        smtp = {
          address = "submission://smtp.gmail.com:587";
          username = config.my.defaults.email;
          sender = "authelia@${domain}";
        };
      };
      identity_providers.oidc.clients = [
        {
          authorization_policy = "one_factor";
          client_id = "jellyfin";
          client_secret = "$pbkdf2-sha512$310000$rMliY0u1kEQ0FRHrG8xvqg$8.wKSra2uT5VFhCAv1YQHHnCSSORmWDrdAv6Uns1Ae7yu24w87SW0PmH9BKrYB1YIWoo7RJhF1NtYupQ.YRyRg";
          redirect_uris = ["https://jellyfin.${domain}/sso/OID/r/authelia"];
          token_endpoint_auth_method = "client_secret_post";
        }
        {
          authorization_policy = "one_factor";
          client_id = "deluge";
          client_secret = "$pbkdf2-sha512$310000$wPpdmhrPqd.dU.tcLTh9nQ$du11GENjjxaXf5njeqnhpVgr8O9fCISulobjRStCsYJzY6i3aaOyiloRJHKDh.CC.4n1QVqsP.ty9Lo8UH3XvA";
          redirect_uris = ["https://deluge.${domain}/oauth-callback"];
          scopes = ["openid" "profile" "email"];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_post";
        }
      ];
    };
  };

  # Firewall configuration
  networking.firewall.allowedTCPPorts = [
    9000 # Authelia
  ];

  systemd.services.authelia.after = ["lldap.service" "postgresql.service" "redis-homeserver.service"];
}
