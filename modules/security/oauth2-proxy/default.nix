# {config, ...}: let
#   # OAuth2 Proxy configuration for Keycloak
#   proxyPort = 4180;
#   # Services to protect with OAuth2 Proxy
#   # Format: { subdomain, internal_port, service_name }
#   # Generate nginx auth_request configuration for each service
# in {
#   # =================================================================
#   # SOPS Secrets for OAuth2 Proxy
#   # =================================================================
#   sops.secrets = {
#     oauth2_proxy_client_secret = {
#       sopsFile = ../../../secrets/keycloak.yaml;
#       key = "oauth2_proxy_client_secret";
#       owner = config.users.users.oauth2-proxy.name;
#       group = config.users.groups.oauth2-proxy.name;
#       mode = "0440";
#     };
#     oauth2_proxy_cookie_secret = {
#       sopsFile = ../../../secrets/keycloak.yaml;
#       key = "oauth2_proxy_cookie_secret";
#       owner = config.users.users.oauth2-proxy.name;
#       group = config.users.groups.oauth2-proxy.name;
#       mode = "0400";
#     };
#   };
#   # =================================================================
#   # Users and Groups
#   # =================================================================
#   users.groups.oauth2-proxy = {};
#   users.users.oauth2-proxy = {
#     isSystemUser = true;
#     group = "oauth2-proxy";
#   };
#   # =================================================================
#   # OAuth2 Proxy Service
#   # =================================================================
#   services.oauth2-proxy = {
#     enable = true;
#     provider = "keycloak-oidc";
#     # Keycloak configuration
#     clientID = "oauth2-proxy";
#     # Dummy values - actual secrets loaded from files
#     clientSecret = "dummy";
#     cookie.secret = "12345678901234567890123456789012"; # Must be exactly 32 bytes
#     # OIDC configuration
#     extraConfig = {
#       # Secrets loaded from files (these override the dummy values above)
#       client-secret-file = config.sops.secrets.oauth2_proxy_client_secret.path;
#       cookie-secret-file = "%d/cookie_secret";
#       oidc-issuer-url = "https://auth.${config.my.defaults.domain}/realms/master";
#       redirect-url = "https://auth.${config.my.defaults.domain}/oauth2/callback";
#       # Cookie settings
#       cookie-name = "_oauth2_proxy";
#       cookie-secure = "true";
#       cookie-httponly = "true";
#       cookie-samesite = "lax";
#       cookie-domain = ".${config.my.defaults.domain}";
#       # Session settings
#       session-store-type = "cookie";
#       # Email and user configuration
#       email-domain = "*";
#       whitelist-domain = ".${config.my.defaults.domain}";
#       # Upstream configuration
#       http-address = "127.0.0.1:${toString proxyPort}";
#       # Logging
#       request-logging = "true";
#       auth-logging = "true";
#       # Security
#       skip-provider-button = "true";
#       # Reverse proxy settings
#       reverse-proxy = "true";
#       real-client-ip-header = "X-Forwarded-For";
#       # Scopes
#       scope = "openid profile email";
#       # Allow all authenticated users
#       skip-auth-regex = [
#         "^/ping$"
#         "^/health$"
#       ];
#     };
#   };
#   # =================================================================
#   # Systemd Service Hardening
#   # =================================================================
#   systemd.services.oauth2-proxy = {
#     after = ["keycloak.service"];
#     wants = ["keycloak.service"];
#     serviceConfig = {
#       # Load cookie secret from SOPS
#       LoadCredential = [
#         "cookie_secret:${config.sops.secrets.oauth2_proxy_cookie_secret.path}"
#       ];
#       # Restart configuration - keep retrying until Keycloak is ready
#       RestartSec = "5s";
#       StartLimitBurst = 10;
#       StartLimitIntervalSec = 60;
#       # Security hardening
#       NoNewPrivileges = true;
#       PrivateTmp = true;
#       ProtectHome = true;
#       ProtectSystem = "strict";
#       # Resource limits
#       MemoryMax = "256M";
#       CPUQuota = "50%";
#     };
#   };
#   # =================================================================
#   # Firewall
#   # =================================================================
#   networking.firewall.allowedTCPPorts = [
#     proxyPort
#   ];
# }
{config, ...}: let
  domain = rec {
    root = "example.com";
    oauth2-proxy = "oauth2-proxy.${root}";
    sso = "auth.${root}";
  };
  port = 4180;
  realm = "homelab";
in {
  services = {
    oauth2-proxy = {
      enable = true;

      reverseProxy = true;
      httpAddress = "http://[::1]:${toString port}";

      nginx = {
        domain = domain.oauth2-proxy;
        proxy = config.services.oauth2-proxy.httpAddress;
      };

      provider = "keycloak-oidc";
      oidcIssuerUrl = "https://${domain.sso}/realms/${realm}";
      redirectURL = "https://${domain.oauth2-proxy}/oauth2/callback";
      email.domains = ["*"];
      cookie = {
        domain = ".${domain.root}";
        secure = true;
      };
      keyFile = config.age.secrets.oauth2-proxy-secrets-env.path;
      extraConfig = {
        client-id = "oauth2-proxy";
        skip-provider-button = true;
        code-challenge-method = "S256";
        provider-display-name = "Keycloak";
        whitelist-domain = ["*.nukdokplex.ru"];
        session-store-type = "redis";
        redis-connection-url = "unix://${config.services.redis.servers.oauth2-proxy.unixSocket}";
        # skip-jwt-bearer-tokens = true;
      };
      setXauthrequest = true;
      passAccessToken = true;
    };

    redis.servers.oauth2-proxy = {
      enable = true;
      unixSocketPerm = 660;
      group = "oauth2-proxy";
    };

    nginx.virtualHosts.${config.services.oauth2-proxy.nginx.domain} = {
      serverName = domain.oauth2-proxy;
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://[::1]:${toString port}";
        proxyWebsockets = true;
      };
    };
  };

  systemd.services.oauth2-proxy = {
    after = ["redis-oauth2-proxy.service"];
    # Don't give up trying to start oauth2-proxy, even if keycloak isn't up yet
    # https://gist.github.com/benley/78a5e84c52131f58d18319bf26d52cda
    startLimitIntervalSec = 0;
    serviceConfig = {
      RestartSec = 1;
    };
  };

  age.secrets = {
    oauth2-proxy-cookie-secret = {
      intermediary = true;
      generator.script = {
        pkgs,
        lib,
        ...
      }: "${lib.getExe pkgs.openssl} rand -base64 32 | tr -- '+/' '-_'";
    };
    oauth2-proxy-client-secret = {
      intermediary = true;
    };
    oauth2-proxy-secrets-env = {
      generator = {
        dependencies = {
          inherit
            (config.age.secrets)
            oauth2-proxy-cookie-secret
            oauth2-proxy-client-secret
            ;
        };
        script = {
          decrypt,
          deps,
          lib,
          ...
        }: ''
          cat << EOF
          OAUTH2_PROXY_COOKIE_SECRET="$(${decrypt} ${lib.escapeShellArg deps.oauth2-proxy-cookie-secret.file})"
          OAUTH2_PROXY_CLIENT_SECRET="$(${decrypt} ${lib.escapeShellArg deps.oauth2-proxy-client-secret.file})"
          EOF
        '';
      };
      owner = "oauth2-proxy";
      group = "oauth2-proxy";
      mode = "0400";
    };
  };
}
