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

    # WebAuthn (YubiKey/FIDO2) configuration
    webAuthnPolicyRpEntityName = "Homelab";
    webAuthnPolicyRpId = domain;
    webAuthnPolicySignatureAlgorithms = ["ES256" "RS256"];
    webAuthnPolicyAttestationConveyancePreference = "none";
    webAuthnPolicyAuthenticatorAttachment = "cross-platform";
    webAuthnPolicyRequireResidentKey = "No";
    webAuthnPolicyUserVerificationRequirement = "preferred";
    webAuthnPolicyCreateTimeout = 60;
    webAuthnPolicyAvoidSameAuthenticatorRegister = false;
    webAuthnPolicyAcceptableAaguids = [];

    # WebAuthn Passwordless configuration
    webAuthnPolicyPasswordlessRpEntityName = "Homelab";
    webAuthnPolicyPasswordlessRpId = domain;
    webAuthnPolicyPasswordlessSignatureAlgorithms = ["ES256" "RS256"];
    webAuthnPolicyPasswordlessAttestationConveyancePreference = "none";
    webAuthnPolicyPasswordlessAuthenticatorAttachment = "cross-platform";
    webAuthnPolicyPasswordlessRequireResidentKey = "Yes";
    webAuthnPolicyPasswordlessUserVerificationRequirement = "required";
    webAuthnPolicyPasswordlessCreateTimeout = 60;
    webAuthnPolicyPasswordlessAvoidSameAuthenticatorRegister = false;
    webAuthnPolicyPasswordlessAcceptableAaguids = [];

    # Email settings - Gmail SMTP
    # Note: SMTP credentials are automatically configured from SOPS secrets
    # Username: config.my.defaults.email
    # Password: From secrets/gmail_conf.yaml (gmail_password key)
    smtpServer = {
      host = "smtp.gmail.com";
      port = "587";
      from = config.my.defaults.email;
      fromDisplayName = "Homelab Auth";
      ssl = "false";
      starttls = "true";
      auth = "true";
      # Credentials are set automatically via realm import script
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
      "UPDATE_TOTP"
      "REMOVE_TOTP"
    ];
    adminEventsEnabled = true;
    adminEventsDetailsEnabled = true;

    # Required actions - includes WebAuthn registration
    requiredActions = [
      {
        alias = "CONFIGURE_TOTP";
        name = "Configure OTP";
        providerId = "CONFIGURE_TOTP";
        enabled = true;
        defaultAction = false;
        priority = 10;
        config = {};
      }
      {
        alias = "UPDATE_PASSWORD";
        name = "Update Password";
        providerId = "UPDATE_PASSWORD";
        enabled = true;
        defaultAction = false;
        priority = 30;
        config = {};
      }
      {
        alias = "UPDATE_PROFILE";
        name = "Update Profile";
        providerId = "UPDATE_PROFILE";
        enabled = true;
        defaultAction = false;
        priority = 40;
        config = {};
      }
      {
        alias = "VERIFY_EMAIL";
        name = "Verify Email";
        providerId = "VERIFY_EMAIL";
        enabled = true;
        defaultAction = false;
        priority = 50;
        config = {};
      }
      {
        alias = "webauthn-register";
        name = "WebAuthn Register";
        providerId = "webauthn-register";
        enabled = true;
        defaultAction = false;
        priority = 70;
        config = {};
      }
      {
        alias = "webauthn-register-passwordless";
        name = "WebAuthn Register Passwordless";
        providerId = "webauthn-register-passwordless";
        enabled = true;
        defaultAction = false;
        priority = 80;
        config = {};
      }
    ];
  });
in {
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

  config = {
    my.keycloak = {
      realm = realmName;
      authUrl = "https://auth.${domain}/realms/${realmName}/protocol/openid-connect/auth";
      tokenUrl = "https://auth.${domain}/realms/${realmName}/protocol/openid-connect/token";
      userInfoUrl = "https://auth.${domain}/realms/${realmName}/protocol/openid-connect/userinfo";
      logoutUrl = "https://auth.${domain}/realms/${realmName}/protocol/openid-connect/logout";
    };

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

        # Read secrets
        ADMIN_PASSWORD=$(cat ${config.sops.secrets.keycloak_admin_password.path})
        GMAIL_PASSWORD=$(cat ${config.sops.secrets.gmail_password.path})

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

        # Configure SMTP settings (must be done via API as they're sensitive)
        echo "Configuring SMTP settings..."
        ${kcadm} update realms/${realmName} \
          -s 'smtpServer.host=smtp.gmail.com' \
          -s 'smtpServer.port=587' \
          -s 'smtpServer.from=${config.my.defaults.email}' \
          -s 'smtpServer.fromDisplayName=Homelab Auth' \
          -s 'smtpServer.ssl=false' \
          -s 'smtpServer.starttls=true' \
          -s 'smtpServer.auth=true' \
          -s 'smtpServer.user=${config.my.defaults.email}' \
          -s "smtpServer.password=$GMAIL_PASSWORD"

        echo "Realm configuration import completed successfully!"
      '';
    };
  };
}
