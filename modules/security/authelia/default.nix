{config, ...}: let
  authelia = config.services.authelia.instances.main;
  redis = config.services.redis.servers.homeserver;
  port = 9000;
  inherit (config.my.defaults) domain user;
in {
  # SOPS secrets for Authelia
  sops.secrets = {
    authelia_jwt_secret = {
      sopsFile = ../../../secrets/authelia.yaml;
      key = "jwt_secret";
      owner = authelia.user;
      mode = "0400";
    };
    authelia_hmac_secret = {
      sopsFile = ../../../secrets/authelia.yaml;
      key = "hmac_secret";
      owner = authelia.user;
      mode = "0400";
    };
    authelia_issuer_priv_key = {
      sopsFile = ../../../secrets/authelia.yaml;
      key = "issuer_priv_key.pem";
      owner = authelia.user;
      mode = "0400";
    };
    authelia_session_secret = {
      sopsFile = ../../../secrets/authelia.yaml;
      key = "session_secret";
      owner = authelia.user;
      mode = "0400";
    };
    authelia_storage_encryption_key = {
      sopsFile = ../../../secrets/authelia.yaml;
      key = "storage_encryption_key";
      owner = authelia.user;
      mode = "0400";
    };
  };

  environment.systemPackages = [config.services.authelia.instances.main.package];

  users.users.authelia = {
    isSystemUser = true;
    group = "authelia";
    extraGroups = [
      "redis"
      "postgres"
      "msmtp"
      "lldap"
    ];
  };
  users.groups.authelia = {};

  users.users."${user}".extraGroups = ["authelia"];

  # Authelia service configuration (proxied by Traefik)
  services.authelia.instances.main = {
    enable = true;
    user = "authelia";
    secrets = {
      jwtSecretFile = config.sops.secrets.authelia_jwt_secret.path;
      oidcHmacSecretFile = config.sops.secrets.authelia_hmac_secret.path;
      oidcIssuerPrivateKeyFile = config.sops.secrets.authelia_issuer_priv_key.path;
      sessionSecretFile = config.sops.secrets.authelia_session_secret.path;
      storageEncryptionKeyFile = config.sops.secrets.authelia_storage_encryption_key.path;
    };
    environmentVariables = {
      AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = config.sops.secrets.lldap_user_pass.path;
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
          base_dn = "dc=labhome,dc=work";
          additional_users_dn = "ou=people";
          users_filter = "(&({username_attribute}={input})(objectClass=person))";
          additional_groups_dn = "ou=groups";
          groups_filter = "(member={dn})";
          user = "uid=admin,ou=people,dc=labhome,dc=work";
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
          client_secret = "$pbkdf2-sha512$310000$O3AaVIp.a0vTGZClL/077w$05zVMYkb.JhHv.7Fm3bDIQuQCSFrkH99tssuYRpjnIDAr0xnUjWCjGam6ALMV1QtYBC1HPUAge0NSFjMhrfn2g";
          redirect_uris = ["https://jellyfin.${domain}/sso/OID/r/authelia"];
          token_endpoint_auth_method = "client_secret_post";
        }
        {
          authorization_policy = "one_factor";
          client_id = "deluge";
          client_secret = "$pbkdf2-sha512$310000$jBwK1WmvrZF5lFwcUKYcXA$OT9Trx7oEztmPIepqMJv/o.SGQf01gV2Hxmx9vYmjDrC32JEk984JlRD06.cIsiI6pWd07W2Ann71281Gh/u1A";
          redirect_uris = ["https://deluge.${domain}/oauth-callback"];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_post";
        }
        {
          authorization_policy = "one_factor";
          client_id = "grafana";
          client_secret = "$pbkdf2-sha512$310000$2h6vczoKorfBcG/H9ZDqNA$EV9OqqWrMlRoTflmZMYj9rDUjr6LrbDgx/G9YJRGgG7zKeekWOBnFH8SvEzzg4L/NFyZ7u1AjolksUzOIMnmvQ";
          scopes = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
          token_endpoint_auth_method = "client_secret_post";
        }
        {
          authorization_policy = "one_factor";
          client_id = "miniflux";
          client_secret = "$pbkdf2-sha512$310000$AnAp9BqRGMt9ZqMwZ4WsHQ$PtSKXkEmDdlqD3MwDlJ98cnazNB1eQLxK2o7eBauDxdQRCsMp4nGj/Q3njTpJVmh9TZ7ECkF1A8/0LTivFbCDw";
          redirect_uris = ["https://miniflux.${domain}/oauth2/oidc/callback"];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          token_endpoint_auth_method = "client_secret_post";
        }
        {
          authorization_policy = "one_factor";
          client_id = "kavita";
          client_secret = "$pbkdf2-sha512$310000$ukp9l/M9a/k2HLaLwdgmGA$MGjXsJjLIiE6FPLPfNlo2HOrirRFNt47uE677sUQ0zbxrMhxLltCTUfAe07K/NOJW8HT0pdFL3Ik7jgxm7TS1w";
          redirect_uris = ["https://kavita.${domain}/registration/confirm-migration-link"];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          token_endpoint_auth_method = "client_secret_post";
        }
        {
          authorization_policy = "one_factor";
          client_id = "audiobookshelf";
          client_secret = "$pbkdf2-sha512$310000$JwO58hiz.ZVGuJqFCmUjwA$cZC0tI7Wz36aFwrNGDrwP/2Q8xYU3Ul6b.QWK.GNl5jfrRu2KQbOnIH5NFTQqUil5ouQ/5d1EfS6upzIP1dHMQ"; # Replace with actual hash
          redirect_uris = [
            "https://audiobookshelf.${domain}/auth/openid/callback"
            "https://audiobookshelf.${domain}/auth/openid/mobile-redirect"
          ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          token_endpoint_auth_method = "client_secret_post";
        }
      ];
    };
  };

  # Firewall configuration
  networking.firewall.allowedTCPPorts = [
    9000 # Authelia
  ];

  systemd.services.authelia.after = [
    "lldap.service"
    "postgresql.service"
    "redis-homeserver.service"
  ];
}
