{
  config,
  ...
}: let
  # OAuth2 Proxy configuration for Keycloak
  proxyPort = 4180;

  # Services to protect with OAuth2 Proxy
  # Format: { subdomain, internal_port, service_name }
  protectedServices = [
    { subdomain = "home"; port = 8082; name = "homepage-dashboard"; }
    { subdomain = "kavita"; port = 5000; name = "kavita"; }
    { subdomain = "microbin"; port = 8069; name = "microbin"; }
    { subdomain = "miniflux"; port = 8086; name = "miniflux"; }
    # Nixarr services
    { subdomain = "jellyfin"; port = 8096; name = "jellyfin"; }
    { subdomain = "sonarr"; port = 8989; name = "sonarr"; }
    { subdomain = "radarr"; port = 7878; name = "radarr"; }
    { subdomain = "prowlarr"; port = 9696; name = "prowlarr"; }
    { subdomain = "bazarr"; port = 6767; name = "bazarr"; }
    { subdomain = "lidarr"; port = 8686; name = "lidarr"; }
    { subdomain = "readarr"; port = 8787; name = "readarr"; }
    { subdomain = "jellyseerr"; port = 5055; name = "jellyseerr"; }
    { subdomain = "audiobookshelf"; port = 9292; name = "audiobookshelf"; }
  ];

  # Generate nginx auth_request configuration for each service
  mkAuthRequestConfig = service: {
    "https://${service.subdomain}.${config.my.defaults.domain}/oauth2/" = {
      proxyPass = "http://127.0.0.1:${toString proxyPort}";
      extraConfig = ''
        proxy_set_header X-Scheme $scheme;
        proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
      '';
    };
    "= /oauth2/auth" = {
      proxyPass = "http://127.0.0.1:${toString proxyPort}";
      extraConfig = ''
        internal;
        proxy_set_header X-Scheme $scheme;
        proxy_set_header X-Original-URI $request_uri;
        proxy_set_header X-Forwarded-Host $host;
      '';
    };
  };
in {
  # =================================================================
  # SOPS Secrets for OAuth2 Proxy
  # =================================================================
  sops.secrets = {
    oauth2_proxy_client_secret = {
      sopsFile = ../../../secrets/keycloak.yaml;
      key = "oauth2_proxy_client_secret";
      owner = "oauth2-proxy";
      group = "oauth2-proxy";
      mode = "0400";
    };
    oauth2_proxy_cookie_secret = {
      sopsFile = ../../../secrets/keycloak.yaml;
      key = "oauth2_proxy_cookie_secret";
      owner = "oauth2-proxy";
      group = "oauth2-proxy";
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
    clientSecretFile = config.sops.secrets.oauth2_proxy_client_secret.path;
    cookieSecretFile = config.sops.secrets.oauth2_proxy_cookie_secret.path;

    # OIDC configuration
    extraConfig = {
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
