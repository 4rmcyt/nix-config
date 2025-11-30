{config, ...}: let
  # OAuth2 Proxy configuration for Keycloak
  proxyPort = 4180;
  # Services to protect with OAuth2 Proxy
  # Format: { subdomain, internal_port, service_name }
  # Generate nginx auth_request configuration for each service
in {
  # =================================================================
  # SOPS Secrets for OAuth2 Proxy
  # =================================================================
  sops.secrets = {
    oauth2_proxy_client_secret = {
      sopsFile = ../../../secrets/keycloak.yaml;
      key = "oauth2_proxy_client_secret";
      owner = config.users.users.oauth2-proxy.name;
      group = config.users.groups.oauth2-proxy.name;
      mode = "0400";
    };
    oauth2_proxy_cookie_secret = {
      sopsFile = ../../../secrets/keycloak.yaml;
      key = "oauth2_proxy_cookie_secret";
      owner = config.users.users.oauth2-proxy.name;
      group = config.users.groups.oauth2-proxy.name;
      mode = "0400";
    };
  };

  # =================================================================
  # Users and Groups
  # =================================================================
  users.groups.oauth2-proxy = {};
  users.users.oauth2-proxy = {
    isSystemUser = true;
    group = "oauth2-proxy";
  };

  # =================================================================
  # OAuth2 Proxy Service
  # =================================================================
  services.oauth2-proxy = {
    enable = true;

    provider = "keycloak-oidc";

    # Keycloak configuration
    clientID = "oauth2-proxy";

    # Dummy values - actual secrets loaded from files
    clientSecret = "dummy";
    cookie.secret = "12345678901234567890123456789012"; # Must be exactly 32 bytes

    # OIDC configuration
    extraConfig = {
      # Secrets loaded from files (these override the dummy values above)
      client-secret-file = config.sops.secrets.oauth2_proxy_client_secret.path;
      cookie-secret-file = "%d/cookie_secret";

      oidc-issuer-url = "https://auth.${config.my.defaults.domain}/realms/master";
      redirect-url = "https://auth.${config.my.defaults.domain}/oauth2/callback";

      # Cookie settings
      cookie-name = "_oauth2_proxy";
      cookie-secure = "true";
      cookie-httponly = "true";
      cookie-samesite = "lax";
      cookie-domain = ".${config.my.defaults.domain}";

      # Session settings
      session-store-type = "cookie";

      # Email and user configuration
      email-domain = "*";
      whitelist-domain = ".${config.my.defaults.domain}";

      # Upstream configuration
      http-address = "127.0.0.1:${toString proxyPort}";

      # Logging
      request-logging = "true";
      auth-logging = "true";

      # Security
      skip-provider-button = "true";

      # Reverse proxy settings
      reverse-proxy = "true";
      real-client-ip-header = "X-Forwarded-For";

      # Scopes
      scope = "openid profile email";

      # Allow all authenticated users
      skip-auth-regex = [
        "^/ping$"
        "^/health$"
      ];
    };
  };

  # =================================================================
  # Systemd Service Hardening
  # =================================================================
  systemd.services.oauth2-proxy = {
    serviceConfig = {
      # Load cookie secret from SOPS
      LoadCredential = [
        "cookie_secret:${config.sops.secrets.oauth2_proxy_cookie_secret.path}"
      ];

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";

      # Resource limits
      MemoryMax = "256M";
      CPUQuota = "50%";
    };
  };

  # =================================================================
  # Firewall
  # =================================================================
  networking.firewall.allowedTCPPorts = [
    proxyPort
  ];
}
