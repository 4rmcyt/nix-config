{
  config,
  pkgs,
  lib,
  ...
}: let
  # Realm configuration
  realmName = "homelab";
  inherit (config.my.defaults) domain;

  # Generate realm configuration JSON
  realmConfig = pkgs.writeText "homelab-realm.json" (builtins.toJSON {
    realm = realmName;
    enabled = true;
    displayName = "Homelab Services";
    displayNameHtml = "<div class=\"kc-logo-text\"><span>Homelab</span></div>";

    # Session and token settings
    ssoSessionIdleTimeout = 1800; # 30 minutes
    ssoSessionMaxLifespan = 36000; # 10 hours
    accessTokenLifespan = 300; # 5 minutes
    accessTokenLifespanForImplicitFlow = 900; # 15 minutes

    # Security settings
    loginWithEmailAllowed = true;
    duplicateEmailsAllowed = false;
    resetPasswordAllowed = true;
    editUsernameAllowed = false;
    bruteForceProtected = true;
    permanentLockout = false;
    maxFailureWaitSeconds = 900;
    minimumQuickLoginWaitSeconds = 60;
    waitIncrementSeconds = 60;
    quickLoginCheckMilliSeconds = 1000;
    maxDeltaTimeSeconds = 43200;
    failureFactor = 30;

    # Email settings (configure your SMTP later)
    smtpServer = {
      # host = "smtp.example.com";
      # port = "587";
      # from = "noreply@${domain}";
      # fromDisplayName = "Homelab Auth";
      # ssl = "false";
      # starttls = "true";
      # auth = "true";
    };

    # Default roles
    roles = {
      realm = [
        {
          name = "user";
          description = "Basic user role";
        }
        {
          name = "admin";
          description = "Administrator role";
        }
        {
          name = "grafana-admin";
          description = "Grafana administrator";
        }
        {
          name = "grafana-editor";
          description = "Grafana editor";
        }
        {
          name = "grafana-viewer";
          description = "Grafana viewer";
        }
      ];
    };

    # Default groups
    groups = [
      {
        name = "Users";
        path = "/Users";
        realmRoles = ["user"];
      }
      {
        name = "Admins";
        path = "/Admins";
        realmRoles = ["admin" "user"];
      }
      {
        name = "Grafana Admins";
        path = "/Grafana Admins";
        realmRoles = ["grafana-admin"];
      }
      {
        name = "Grafana Editors";
        path = "/Grafana Editors";
        realmRoles = ["grafana-editor"];
      }
    ];

    # OAuth2 Proxy client (for general service authentication)
    clients = [
      {
        clientId = "oauth2-proxy";
        name = "OAuth2 Proxy";
        description = "OAuth2 Proxy for service authentication";
        enabled = true;
        clientAuthenticatorType = "client-secret";
        secret = "PLACEHOLDER_OAUTH2_PROXY_SECRET"; # Replace via admin console or SOPS
        redirectUris = [
          "https://auth.${domain}/oauth2/callback"
          "https://*.${domain}/oauth2/callback"
        ];
        webOrigins = ["https://*.${domain}"];
        standardFlowEnabled = true;
        directAccessGrantsEnabled = false;
        publicClient = false;
        protocol = "openid-connect";
        attributes = {
          "access.token.lifespan" = "300";
          "pkce.code.challenge.method" = "S256";
        };
        defaultClientScopes = [
          "profile"
          "email"
          "roles"
        ];
      }
      {
        clientId = "grafana";
        name = "Grafana";
        description = "Grafana monitoring dashboard";
        enabled = true;
        clientAuthenticatorType = "client-secret";
        secret = "PLACEHOLDER_GRAFANA_SECRET"; # Replace via admin console or SOPS
        redirectUris = [
          "https://grafana.${domain}/*"
        ];
        webOrigins = ["https://grafana.${domain}"];
        standardFlowEnabled = true;
        directAccessGrantsEnabled = false;
        publicClient = false;
        protocol = "openid-connect";
        defaultClientScopes = [
          "profile"
          "email"
          "roles"
        ];
        protocolMappers = [
          {
            name = "groups";
            protocol = "openid-connect";
            protocolMapper = "oidc-group-membership-mapper";
            config = {
              "full.path" = "false";
              "id.token.claim" = "true";
              "access.token.claim" = "true";
              "claim.name" = "groups";
              "userinfo.token.claim" = "true";
            };
          }
        ];
      }
    ];

    # Client scopes
    clientScopes = [
      {
        name = "roles";
        description = "OpenID Connect scope for roles";
        protocol = "openid-connect";
        attributes = {
          "include.in.token.scope" = "true";
          "display.on.consent.screen" = "false";
        };
      }
    ];

    # Browser security headers
    browserSecurityHeaders = {
      contentSecurityPolicy = "frame-src 'self'; frame-ancestors 'self'; object-src 'none';";
      xContentTypeOptions = "nosniff";
      xFrameOptions = "SAMEORIGIN";
      xRobotsTag = "none";
      xXSSProtection = "1; mode=block";
      strictTransportSecurity = "max-age=31536000; includeSubDomains";
    };

    # Internationalization
    internationalizationEnabled = true;
    supportedLocales = ["en" "de" "es" "fr" "it" "ja" "pt-BR" "ru" "zh-CN"];
    defaultLocale = "en";

    # Events configuration
    eventsEnabled = true;
    eventsListeners = ["jboss-logging"];
    enabledEventTypes = [
      "LOGIN"
      "LOGIN_ERROR"
      "LOGOUT"
      "REGISTER"
      "REGISTER_ERROR"
      "UPDATE_PASSWORD"
      "UPDATE_PASSWORD_ERROR"
    ];
    adminEventsEnabled = true;
    adminEventsDetailsEnabled = true;
  });
in {
  # Add realm import systemd service
  systemd.services.keycloak-realm-import = {
    description = "Import Keycloak Realm Configuration";
    after = ["keycloak.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = config.users.users.keycloak.name;
      Group = config.users.groups.keycloak.name;
    };

    script = let
      kcadm = "${pkgs.keycloak}/bin/kcadm.sh";
      keycloakUrl = "http://127.0.0.1:${toString config.services.keycloak.settings.http-port}";
    in ''
      # Wait for Keycloak to be ready
      echo "Waiting for Keycloak to start..."
      for i in {1..60}; do
        if ${pkgs.curl}/bin/curl -s ${keycloakUrl}/health/ready | grep -q "UP"; then
          echo "Keycloak is ready!"
          break
        fi
        if [ $i -eq 60 ]; then
          echo "Timeout waiting for Keycloak to start"
          exit 1
        fi
        sleep 2
      done

      # Read admin password
      ADMIN_PASSWORD=$(cat ${config.sops.secrets.keycloak_admin_password.path})

      # Authenticate with Keycloak
      ${kcadm} config credentials \
        --server ${keycloakUrl} \
        --realm master \
        --user admin \
        --password "$ADMIN_PASSWORD"

      # Check if realm exists
      if ${kcadm} get realms/${realmName} &>/dev/null; then
        echo "Realm '${realmName}' already exists, updating..."
        ${kcadm} update realms/${realmName} -f ${realmConfig}
      else
        echo "Creating realm '${realmName}'..."
        ${kcadm} create realms -f ${realmConfig}
      fi

      echo "Realm configuration import completed successfully!"
    '';
  };

  # Expose realm name as an option for other modules
  options.my.keycloak = {
    realm = lib.mkOption {
      type = lib.types.str;
      default = realmName;
      description = "The name of the Keycloak realm";
    };

    authUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://auth.${domain}/realms/${realmName}/protocol/openid-connect/auth";
      description = "OAuth authorization URL";
    };

    tokenUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://auth.${domain}/realms/${realmName}/protocol/openid-connect/token";
      description = "OAuth token URL";
    };

    userInfoUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://auth.${domain}/realms/${realmName}/protocol/openid-connect/userinfo";
      description = "OAuth userinfo URL";
    };

    logoutUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://auth.${domain}/realms/${realmName}/protocol/openid-connect/logout";
      description = "OAuth logout URL";
    };
  };

  config.my.keycloak = {
    realm = realmName;
    authUrl = "https://auth.${domain}/realms/${realmName}/protocol/openid-connect/auth";
    tokenUrl = "https://auth.${domain}/realms/${realmName}/protocol/openid-connect/token";
    userInfoUrl = "https://auth.${domain}/realms/${realmName}/protocol/openid-connect/userinfo";
    logoutUrl = "https://auth.${domain}/realms/${realmName}/protocol/openid-connect/logout";
  };
}
