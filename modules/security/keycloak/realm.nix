{
  pkgs,
  config,
  ...
}: let
  inherit (config.my.defaults) domain;
  realmName = "homelab";
  realm = {
    realm = realmName;
    enabled = true;
    displayName = "Homelab Services";
    displayNameHtml = "<div class=\"kc-logo-text\"><span>Homelab</span></div>";

    authUrl = "https://auth.${domain}/realms/${realmName}/protocol/openid-connect/auth";
    tokenUrl = "https://auth.${domain}/realms/${realmName}/protocol/openid-connect/token";
    userInfoUrl = "https://auth.${domain}/realms/${realmName}/protocol/openid-connect/userinfo";
    logoutUrl = "https://auth.${domain}/realms/${realmName}/protocol/openid-connect/logout";

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
    webAuthnPolicySignatureAlgorithms = [
      "ES256"
      "RS256"
    ];
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
    webAuthnPolicyPasswordlessSignatureAlgorithms = [
      "ES256"
      "RS256"
    ];
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

    clients = [
      {
        clientId = "oauth2-proxy";
        description = "OAuth2 Proxy for service authentication";
        rootUrl = "http://localhost:4180";
        clientAuthenticatorType = "client-secret";
        secret = "@@OAUTH2_PROXY_CLIENT_SECRET@@";
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
        secret = "@@GRAFANA_CLIENT_SECRET@@";
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
    # Users should be created manually via admin console or via API
    # This ensures passwords are properly managed via SOPS secrets
    users = [];
    groups = [
      {
        name = "Users";
        path = "/Users";
        realmRoles = ["user"];
      }
      {
        name = "Admins";
        path = "/Admins";
        realmRoles = [
          "admin"
          "user"
        ];
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
    supportedLocales = [
      "en"
      "ru"
      "he"
    ];
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
  };
in {
  # Expose the realm template for use by default.nix
  # The template contains placeholders (@@OAUTH2_PROXY_CLIENT_SECRET@@, etc.)
  # that will be substituted with SOPS secrets at runtime
  services.keycloak.realmTemplate = pkgs.writeText "homelab-realm-template.json" (builtins.toJSON realm);

  # Point Keycloak to the runtime-generated realm file
  # The actual file is created by keycloak-prepare-realm.service in default.nix
  services.keycloak.realmFiles = [
    "/var/lib/keycloak/realm-configs/homelab-realm.json"
  ];
}
