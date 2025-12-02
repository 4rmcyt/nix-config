{config, ...}: let
  domain = rec {
    root = "example.com";
    oauth2-proxy = "oauth2-proxy.${root}";
    sso = "auth.${root}";
  };
  port = 4180;
  realm = "homelab";
in {
  # =================================================================
  # Users and Groups
  # =================================================================
  users.groups.oauth2-proxy = {};
  users.users.oauth2-proxy = {
    isSystemUser = true;
    group = "oauth2-proxy";
  };

  # =================================================================
  # SOPS Secrets
  # =================================================================
  # NOTE: You need to create secrets/oauth2-proxy.yaml with the following keys:
  # - OAUTH2_PROXY_CLIENT_ID
  # - OAUTH2_PROXY_CLIENT_SECRET
  # - OAUTH2_PROXY_COOKIE_SECRET
  sops.secrets.oauth2-proxy-secrets-env = {
    sopsFile = ../../../secrets/oauth2-proxy.env;
    owner = "oauth2-proxy";
    group = "oauth2-proxy";
    format = "dotenv";
    mode = "0400";
  };

  # =================================================================
  # Services
  # =================================================================
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
      keyFile = config.sops.secrets.oauth2-proxy-secrets-env.path;
      extraConfig = {
        client-id = "oauth2-proxy";
        skip-provider-button = true;
        code-challenge-method = "S256";
        provider-display-name = "Keycloak";
        whitelist-domain = ["*.nukdokplex.ru"];
        session-store-type = "redis";
        redis-connection-url = "unix://${config.services.redis.servers.homeserver.unixSocket}?username=oauth2-proxy&password=${config.sops.secrets.redis-oauth2-proxy-password.path}";
        # skip-jwt-bearer-tokens = true;
      };
      setXauthrequest = true;
      passAccessToken = true;
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
    after = ["redis-homeserver.service"];
    requires = ["redis-homeserver.service"];
    # Don't give up trying to start oauth2-proxy, even if keycloak isn't up yet
    # https://gist.github.com/benley/78a5e84c52131f58d18319bf26d52cda
    startLimitIntervalSec = 0;
    serviceConfig = {
      RestartSec = 1;
    };
  };
}
