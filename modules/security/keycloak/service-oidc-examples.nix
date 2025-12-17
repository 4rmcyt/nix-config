# Example OIDC Configuration for Services
# This file contains example configurations for integrating services with Keycloak OIDC
# Copy relevant sections to your service modules as needed
{
  config,
  ...
}: {
  # =================================================================
  # Example 1: Miniflux with Native OIDC Support
  # =================================================================
  # Add to modules/services/miniflux/default.nix

  sops.secrets.miniflux_oidc_client_secret = {
    sopsFile = ../../../secrets/keycloak-clients.yaml;
    key = "miniflux_client_secret";
    owner = config.users.users.miniflux.name;
    group = config.users.groups.miniflux.name;
    mode = "0400";
  };

  services.miniflux.config = {
    # Existing config...
    OAUTH2_PROVIDER = "oidc";
    OAUTH2_CLIENT_ID = "miniflux";
    OAUTH2_CLIENT_SECRET_FILE = config.sops.secrets.miniflux_oidc_client_secret.path;
    OAUTH2_REDIRECT_URL = "https://miniflux.example.com/oauth2/oidc/callback";
    OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://auth.example.com/realms/homelab";
    OAUTH2_USER_CREATION = "1"; # Auto-create users on first login
  };

  # =================================================================
  # Example 2: Homepage Dashboard with oauth2-proxy Protection
  # =================================================================
  # This protects Homepage using the existing oauth2-proxy setup

  services.nginx.virtualHosts."home.example.com" = {
    forceSSL = true;
    sslCertificate = config.my.security.ssl.certPath;
    sslCertificateKey = config.my.security.ssl.keyPath;

    # OAuth2 proxy endpoint
    locations."/oauth2/" = {
      proxyPass = "http://oauth2-proxy";
      extraConfig = ''
        proxy_set_header X-Scheme                $scheme;
        proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
      '';
    };

    # Protected service
    locations."/" = {
      proxyPass = "http://localhost:8082";
      extraConfig = ''
        # Require authentication via oauth2-proxy
        auth_request /oauth2/auth;
        error_page 401 = /oauth2/sign_in;

        # Pass authentication headers to backend
        auth_request_set $user   $upstream_http_x_auth_request_user;
        auth_request_set $email  $upstream_http_x_auth_request_email;
        auth_request_set $auth_token $upstream_http_x_auth_request_access_token;

        proxy_set_header X-User  $user;
        proxy_set_header X-Email $email;
        proxy_set_header X-Auth-Token $auth_token;
      '';
    };
  };

  # =================================================================
  # Example 3: Kavita with OIDC (Manual Configuration in UI)
  # =================================================================
  # Kavita requires OIDC configuration through its web UI
  # After enabling the service, configure in Kavita Settings:
  # - Authentication → External Authentication Provider
  # - Provider: OpenID Connect
  # - Authority: https://auth.example.com/realms/homelab
  # - Client ID: kavita
  # - Client Secret: <from-keycloak>
  # - Callback Path: /login-callback

  # No nix configuration needed, just ensure service is accessible

  # =================================================================
  # Example 4: Atuin Server with oauth2-proxy Protection
  # =================================================================
  # Atuin may not have native OIDC, so protect with oauth2-proxy

  services.nginx.virtualHosts."atuin.example.com" = {
    forceSSL = true;
    sslCertificate = config.my.security.ssl.certPath;
    sslCertificateKey = config.my.security.ssl.keyPath;

    locations."/oauth2/" = {
      proxyPass = "http://oauth2-proxy";
    };

    locations."/" = {
      proxyPass = "http://localhost:8881";
      extraConfig = ''
        auth_request /oauth2/auth;
        error_page 401 = /oauth2/sign_in;

        auth_request_set $user $upstream_http_x_auth_request_user;
        proxy_set_header X-User $user;
      '';
    };
  };

  # =================================================================
  # Example 5: Microbin with oauth2-proxy Protection
  # =================================================================

  services.nginx.virtualHosts."microbin.example.com" = {
    forceSSL = true;
    sslCertificate = config.my.security.ssl.certPath;
    sslCertificateKey = config.my.security.ssl.keyPath;

    locations."/oauth2/" = {
      proxyPass = "http://oauth2-proxy";
    };

    locations."/" = {
      proxyPass = "http://localhost:8069";
      extraConfig = ''
        auth_request /oauth2/auth;
        error_page 401 = /oauth2/sign_in;

        auth_request_set $user $upstream_http_x_auth_request_user;
        auth_request_set $email $upstream_http_x_auth_request_email;
        proxy_set_header X-Forwarded-User $user;
        proxy_set_header X-Forwarded-Email $email;
      '';
    };
  };

  # =================================================================
  # Example 6: Nixarr Services (Sonarr, Radarr, etc.) with oauth2-proxy
  # =================================================================
  # *arr apps don't support OIDC, so we protect them with oauth2-proxy

  services.nginx.virtualHosts."sonarr.example.com" = {
    forceSSL = true;
    sslCertificate = config.my.security.ssl.certPath;
    sslCertificateKey = config.my.security.ssl.keyPath;

    locations."/oauth2/" = {
      proxyPass = "http://oauth2-proxy";
    };

    locations."/" = {
      proxyPass = "http://localhost:8989";
      proxyWebsockets = true;
      extraConfig = ''
        auth_request /oauth2/auth;
        error_page 401 = /oauth2/sign_in;

        auth_request_set $user $upstream_http_x_auth_request_user;
        proxy_set_header X-User $user;
      '';
    };
  };

  # Similar configuration for other *arr services:
  # - radarr.example.com → localhost:7878
  # - prowlarr.example.com → localhost:9696
  # - lidarr.example.com → localhost:8686
  # - readarr.example.com → localhost:8787
  # - bazarr.example.com → localhost:6767

  # =================================================================
  # oauth2-proxy Configuration Update
  # =================================================================
  # Update modules/security/oauth2-proxy/default.nix to use Keycloak

  services.oauth2-proxy = {
    enable = true;
    provider = "keycloak-oidc";

    # Keycloak OIDC configuration
    oidcIssuerUrl = "https://auth.example.com/realms/homelab";
    clientID = "oauth2-proxy";

    # Additional configuration
    extraConfig = {
      # Existing extraConfig...
      scope = "openid profile email";
      oidc-groups-claim = "groups";
      oidc-email-claim = "email";

      # Allow specific email domains or groups
      # allowed-group = "homelab-users";
      # email-domain = "*";
    };

    cookie = {
      domain = ".example.com";
      secure = true;
      expire = "12h";
    };

    reverseProxy = true;
    httpAddress = "unix:///run/oauth2-proxy/oauth2-proxy.sock";
    redirectURL = "https://oauth2-proxy.example.com/oauth2/callback";
    setXauthrequest = true;

    # Client secret from sops
    keyFile = config.sops.secrets.oauth2-proxy-secrets-env.path;
  };

  # =================================================================
  # Secrets Configuration for OIDC Clients
  # =================================================================
  # Create secrets/keycloak-clients.yaml with client secrets:
  #
  # miniflux_client_secret: ENC[...]
  # oauth2_proxy_client_secret: ENC[...]
  # kavita_client_secret: ENC[...]
  # (etc for other services)

  # Update oauth2-proxy secrets (secrets/oauth2-proxy.env) to include:
  # OAUTH2_PROXY_CLIENT_ID=oauth2-proxy
  # OAUTH2_PROXY_CLIENT_SECRET=<client-secret-from-keycloak>
  # OAUTH2_PROXY_COOKIE_SECRET=<random-32-byte-base64-string>
  # OAUTH2_PROXY_PROVIDER=keycloak-oidc
  # OAUTH2_PROXY_OIDC_ISSUER_URL=https://auth.example.com/realms/homelab
}
