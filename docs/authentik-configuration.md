# Authentik SSO Configuration for Homeserver Services

This document provides a complete configuration guide for integrating all homeserver services with Authentik SSO.

## Table of Contents

- [Overview](#overview)
- [Service Authentication Summary](#service-authentication-summary)
- [Tier 1: Native OIDC Services](#tier-1-native-oidc-services)
- [Tier 2: Plugin-Based Services](#tier-2-plugin-based-services)
- [Tier 3: Proxy-Based Services](#tier-3-proxy-based-services)
- [Tier 4: Special Cases](#tier-4-special-cases)
- [Group and Role Mapping](#group-and-role-mapping)
- [Troubleshooting](#troubleshooting)

---

## Overview

Your homeserver runs 18 services that can be integrated with Authentik for centralized authentication:

**Authentication Methods:**
- **OIDC/OAuth2**: 8 services with native support
- **Reverse Proxy Auth**: 10 services requiring Authentik Proxy Provider
- **LDAP**: 1 service (Radicale) as alternative

**Domain**: `example.com`
**Authentik URL**: `https://auth.example.com`

### About Authorization Flows

In the configurations below, we reference authorization flows. These are built-in flows that Authentik creates automatically on installation.

**To verify your flows:**
1. Log into Authentik at `https://auth.example.com`
2. Go to **Flows & Stages** > **Flows**
3. Look for these flows (names vary by Authentik version):

**Newer Authentik versions (2024.x+):**
- `default-authentication-flow` - For user login
- `default-provider-authorization-explicit-consent` - Shows consent screen
- `default-provider-authorization-implicit-consent` - Auto-consent (no screen)
- `default-invalidation-flow` - For logout

**Older Authentik versions:**
- `default-authentication-flow` - For user login
- `default-authorization-flow` - For OAuth2/OIDC consent
- `default-invalidation-flow` - For logout
- `default-provider-authorization-implicit-consent` - Auto-consent flow

**Flow Selection Guide:**

| Provider Type | Recommended Flow | Alternative | Behavior |
|--------------|------------------|-------------|----------|
| **OAuth2/OIDC Providers** | `default-provider-authorization-explicit-consent` | `default-provider-authorization-implicit-consent` | Shows consent screen / Auto-consents |
| **Proxy Providers** | `default-provider-authorization-implicit-consent` | `default-provider-authorization-explicit-consent` | Auto-login / Shows consent |

**Quick Reference (if you have the newer flow names):**
- **For OIDC apps** (Grafana, Paperless, Miniflux, etc.):
  - Use: `default-provider-authorization-explicit-consent`
  - Why: Shows users what permissions they're granting (more secure)

- **For Proxy apps** (Sonarr, Homepage, etc.):
  - Use: `default-provider-authorization-implicit-consent`
  - Why: Seamless login without extra clicks (better UX)

**Recommendation:**
- **OIDC Providers**: Use `explicit-consent` for better security (users see what permissions they're granting)
- **Proxy Providers**: Use `implicit-consent` for seamless experience (no extra consent click)

**Custom Flows (Optional):**
You can create custom flows if you want to:
- Add additional authentication stages (2FA, password change prompts, etc.)
- Customize the consent screen
- Add custom validation logic
- Implement different authentication methods per application

For the configurations in this document, we'll use the default flows, but you can substitute your own custom flows if you've created them.

---

## Service Authentication Summary

| Service | Port | URL | Auth Method | Complexity |
|---------|------|-----|-------------|-----------|
| **Grafana** | 3003 | grafana.example.com | OIDC Native | ⭐ Low |
| **Audiobookshelf** | 9292 | audiobookshelf.example.com | OIDC Native | ⭐ Low |
| **Paperless-ngx** | 8888 | paperless.example.com | OIDC Native | ⭐ Low |
| **Miniflux** | 8086 | miniflux.example.com | OIDC Native | ⭐ Low |
| **Kavita** | 5000 | kavita.example.com | OIDC Native | ⭐ Low |
| **Jellyseerr** | 5055 | jellyseerr.example.com | OIDC Native | ⭐ Low |
| **Jellyfin** | 8096 | jellyfin.example.com | OIDC Plugin | ⭐⭐ Medium |
| **Home Assistant** | 8123 | hass.example.com | OIDC Plugin | ⭐⭐⭐ High |
| **Sonarr** | 8989 | sonnar.example.com | Proxy Auth | ⭐⭐ Medium |
| **Radarr** | 7878 | radarr.example.com | Proxy Auth | ⭐⭐ Medium |
| **Prowlarr** | 9696 | prowlarr.example.com | Proxy Auth | ⭐⭐ Medium |
| **Bazarr** | 6767 | bazarr.example.com | Proxy Auth | ⭐⭐ Medium |
| **Lidarr** | 8686 | lidarr.example.com | Proxy Auth | ⭐⭐ Medium |
| **Readarr** | 8787 | readarr.example.com | Proxy Auth | ⭐⭐ Medium |
| **Transmission** | 9091 | N/A | Proxy Auth | ⭐⭐ Medium |
| **Homepage** | 8082 | home.example.com | Proxy Auth | ⭐⭐ Medium |
| **Filebrowser** | 8880 | N/A | Proxy Auth | ⭐⭐ Medium |
| **Radicale** | 5232 | cal.example.com | LDAP/Headers | ⭐⭐ Medium |

---

## Tier 1: Native OIDC Services

These services have native OIDC support built-in. Configuration is straightforward.

### 1. Grafana

**Configuration in Authentik:**

1. **Create Provider:**
   - Type: OAuth2/OpenID Provider
   - Name: `Grafana`
   - Authorization flow: `default-provider-authorization-explicit-consent`
   - Client type: `Confidential`
   - Client ID: `grafana`
   - Redirect URIs: `https://grafana.example.com/login/generic_oauth`
   - Scopes: `openid email profile groups`
   - Signing Key: Auto-generated

2. **Create Application:**
   - Name: `Grafana`
   - Slug: `grafana`
   - Provider: Select the provider created above
   - Launch URL: `https://grafana.example.com`

3. **Create Groups for Role Mapping:**
   - `Grafana Admins` (Admin role)
   - `Grafana Editors` (Editor role)
   - Default users get Viewer role

**Configuration in NixOS:**

Add to your Grafana service configuration:

```nix
services.grafana = {
  enable = true;
  settings = {
    server = {
      http_addr = "127.0.0.1";
      http_port = 3003;
      root_url = "https://grafana.example.com";
    };

    "auth.generic_oauth" = {
      enabled = true;
      name = "Authentik";
      client_id = "grafana";
      client_secret = "$__file{${config.sops.secrets.grafana_oauth_secret.path}}";
      scopes = "openid profile email";
      auth_url = "https://auth.example.com/application/o/authorize/";
      token_url = "https://auth.example.com/application/o/token/";
      api_url = "https://auth.example.com/application/o/userinfo/";
      role_attribute_path = "contains(groups, 'Grafana Admins') && 'Admin' || contains(groups, 'Grafana Editors') && 'Editor' || 'Viewer'";
      allow_sign_up = true;
    };
  };
};

# Add secret configuration
sops.secrets.grafana_oauth_secret = {
  sopsFile = ../../../secrets/authentik.yaml;
  key = "grafana_oauth_secret";
  owner = config.users.users.grafana.name;
  mode = "0400";
};
```

---

### 2. Audiobookshelf

**Configuration in Authentik:**

1. **Create Provider:**
   - Type: OAuth2/OpenID Provider
   - Name: `Audiobookshelf`
   - Authorization flow: `default-provider-authorization-explicit-consent`
   - Client type: `Confidential`
   - Client ID: `audiobookshelf`
   - Redirect URIs:
     - `https://audiobookshelf.example.com/auth/openid/callback`
     - `https://audiobookshelf.example.com/auth/openid/mobile-redirect`
   - Scopes: `openid email profile`

2. **Create Application:**
   - Name: `Audiobookshelf`
   - Slug: `audiobookshelf`
   - Provider: Select the provider created above
   - Launch URL: `https://audiobookshelf.example.com`

**Configuration in Audiobookshelf UI:**

1. Go to Settings > Authentication
2. Enable SSO Authentication
3. Fill in:
   - Issuer URL: `https://auth.example.com/application/o/audiobookshelf/`
   - Authorization URL: (auto-populated from discovery)
   - Token URL: (auto-populated from discovery)
   - Userinfo URL: (auto-populated from discovery)
   - Client ID: `audiobookshelf`
   - Client Secret: (from Authentik provider)
   - Button text: `Login with Authentik`
   - Auto Register: Enabled
   - Match Existing Users By: Email

**Bypass SSO (if needed):**
- Navigate to: `https://audiobookshelf.example.com/login/?autoLaunch=0`

---

### 3. Paperless-ngx

**Configuration in Authentik:**

1. **Create Provider:**
   - Type: OAuth2/OpenID Provider
   - Name: `Paperless`
   - Authorization flow: `default-provider-authorization-explicit-consent`
   - Client type: `Confidential`
   - Client ID: `paperless-ngx`
   - Redirect URIs: `https://paperless.example.com/accounts/oidc/authentik/login/callback/`
   - Scopes: `openid email profile`

2. **Create Application:**
   - Name: `Paperless-ngx`
   - Slug: `paperless-ngx`
   - Provider: Select the provider created above
   - Launch URL: `https://paperless.example.com`

**Configuration in NixOS:**

Update your Paperless configuration:

```nix
services.paperless = {
  enable = true;
  settings = {
    # ... existing settings ...

    PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
    PAPERLESS_SOCIALACCOUNT_PROVIDERS = builtins.toJSON {
      openid_connect = {
        APPS = [{
          provider_id = "authentik";
          name = "Authentik";
          client_id = "paperless-ngx";
          secret = "$OIDC_CLIENT_SECRET";
          settings = {
            server_url = "https://auth.example.com/application/o/paperless-ngx/.well-known/openid-configuration";
          };
        }];
        OAUTH_PKCE_ENABLED = true;
      };
    };
  };
};

# Update environment file to include OIDC_CLIENT_SECRET
sops.secrets.paperless_oidc_secret = {
  sopsFile = ../../../secrets/authentik.yaml;
  key = "paperless_oidc_secret";
  owner = config.users.users.paperless.name;
  mode = "0400";
};
```

---

### 4. Miniflux

**Configuration in Authentik:**

1. **Create Provider:**
   - Type: OAuth2/OpenID Provider
   - Name: `Miniflux`
   - Authorization flow: `default-provider-authorization-explicit-consent`
   - Client type: `Confidential`
   - Client ID: `miniflux`
   - Redirect URIs: `https://miniflux.example.com/oauth2/oidc/callback`
   - Scopes: `openid email profile`

2. **Create Application:**
   - Name: `Miniflux`
   - Slug: `miniflux`
   - Provider: Select the provider created above
   - Launch URL: `https://miniflux.example.com`

**Configuration in NixOS:**

Update your Miniflux configuration:

```nix
services.miniflux = {
  enable = true;
  config = {
    # ... existing settings ...

    # OIDC Configuration
    OAUTH2_PROVIDER = "oidc";
    OAUTH2_CLIENT_ID = "miniflux";
    OAUTH2_CLIENT_SECRET = lib.mkForce "${config.sops.secrets.miniflux_oauth_secret.path}";
    OAUTH2_REDIRECT_URL = "https://miniflux.example.com/oauth2/oidc/callback";
    OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://auth.example.com/application/o/miniflux/";
    OAUTH2_USER_CREATION = "1";
  };
};

# Add secret
sops.secrets.miniflux_oauth_secret = {
  sopsFile = ../../../secrets/authentik.yaml;
  key = "miniflux_oauth_secret";
  owner = config.users.users.miniflux.name;
  mode = "0400";
};
```

**Important:** The discovery endpoint should NOT include `.well-known/openid-configuration` - Miniflux's OIDC library adds it automatically.

---

### 5. Kavita

**Configuration in Authentik:**

1. **Create Provider:**
   - Type: OAuth2/OpenID Provider
   - Name: `Kavita`
   - Authorization flow: `default-provider-authorization-explicit-consent`
   - Client type: `Confidential`
   - Client ID: `kavita`
   - Redirect URIs: `https://kavita.example.com/registration/confirm-migration-link`
   - Scopes: `openid email profile`

2. **Create Application:**
   - Name: `Kavita`
   - Slug: `kavita`
   - Provider: Select the provider created above
   - Launch URL: `https://kavita.example.com`

**Configuration in Kavita UI:**

1. Go to Admin Dashboard > Settings > Authentication
2. Enable OpenID Connect
3. Fill in:
   - Authority: `https://auth.example.com/application/o/kavita/`
   - Client ID: `kavita`
   - Client Secret: (from Authentik provider)
   - Enable Auto Account Creation: Yes
   - Enable Role Syncing: Yes (optional)
4. Save and restart Kavita

**Note:** Configuration changes to Authority, Client ID, or Secret require application restart.

---

### 6. Jellyseerr

**Configuration in Authentik:**

1. **Create Provider:**
   - Type: OAuth2/OpenID Provider
   - Name: `Jellyseerr`
   - Authorization flow: `default-provider-authorization-explicit-consent`
   - Client type: `Confidential`
   - Client ID: `jellyseerr`
   - Redirect URIs: `https://jellyseerr.example.com/login/oidc/callback`
   - Scopes: `openid email profile groups`

2. **Create Application:**
   - Name: `Jellyseerr`
   - Slug: `jellyseerr`
   - Provider: Select the provider created above
   - Launch URL: `https://jellyseerr.example.com`

**Configuration in Jellyseerr UI:**

1. Go to Settings > Authentication
2. Enable OIDC Authentication
3. Fill in:
   - Provider Name: `Authentik`
   - Client ID: `jellyseerr`
   - Client Secret: (from Authentik provider)
   - Authorization URL: `https://auth.example.com/application/o/authorize/`
   - Token URL: `https://auth.example.com/application/o/token/`
   - Userinfo URL: `https://auth.example.com/application/o/userinfo/`
   - Discovery URL: `https://auth.example.com/application/o/jellyseerr/.well-known/openid-configuration`
4. Save settings

**Note:** OIDC support is native but still being refined. Users may need to manually link accounts.

---

## Tier 2: Plugin-Based Services

### 7. Jellyfin

**Prerequisites:**
- Install `jellyfin-plugin-sso` from repository

**Configuration in Authentik:**

1. **Create Provider:**
   - Type: OAuth2/OpenID Provider
   - Name: `Jellyfin`
   - Authorization flow: `default-provider-authorization-explicit-consent`
   - Client type: `Confidential`
   - Client ID: `jellyfin`
   - Redirect URIs: `https://jellyfin.example.com/sso/OID/redirect/authentik`
   - Scopes: `openid email profile`

2. **Create Application:**
   - Name: `Jellyfin`
   - Slug: `jellyfin`
   - Provider: Select the provider created above
   - Launch URL: `https://jellyfin.example.com`

**Install SSO Plugin:**

1. In Jellyfin, go to Dashboard > Plugins > Repositories
2. Add repository: `https://raw.githubusercontent.com/9p4/jellyfin-plugin-sso/manifest-release/manifest.json`
3. Go to Catalog, find "SSO Authentication", install
4. Restart Jellyfin

**Configure Plugin:**

1. Go to Dashboard > Plugins > SSO Authentication
2. Add Provider:
   - Provider: OpenID
   - Provider Name: `authentik`
   - Client ID: `jellyfin`
   - Client Secret: (from Authentik)
   - OID Endpoint: `https://auth.example.com/application/o/jellyfin/`
   - Enable folder mapping: Optional
3. Save configuration

**Launch URL:** `https://jellyfin.example.com/sso/OID/start/authentik`

---

### 8. Home Assistant

**Prerequisites:**
- HACS (Home Assistant Community Store) installed
- Create users in Home Assistant before OIDC login

**Configuration in Authentik:**

1. **Create Provider:**
   - Type: OAuth2/OpenID Provider
   - Name: `Home Assistant`
   - Authorization flow: `default-provider-authorization-explicit-consent`
   - Client type: `Public` (important!)
   - Client ID: `homeassistant`
   - Redirect URIs: `https://hass.example.com/auth/oidc/callback`
   - Scopes: `openid email profile`

2. **Create Application:**
   - Name: `Home Assistant`
   - Slug: `home-assistant`
   - Provider: Select the provider created above
   - Launch URL: `https://hass.example.com`

**Install HACS Integration:**

1. In Home Assistant, go to HACS > Integrations
2. Search for "OIDC Auth"
3. Install `hass-oidc-auth` by christiaangoossens
4. Restart Home Assistant

**Configuration in configuration.yaml:**

```yaml
auth_oidc:
  client_id: "homeassistant"
  discovery_url: "https://auth.example.com/application/o/home-assistant/.well-known/openid-configuration"
```

**Important Notes:**
- Users must exist in Home Assistant before OIDC login
- Requires valid SSL certificate or custom CA configuration
- Select "Public Client" in Authentik (not Confidential)

---

## Tier 3: Proxy-Based Services

These services don't have native SSO support and require Authentik's Proxy Provider with Forward Authentication.

### General Setup Pattern

**For each service:**

1. **Create Proxy Provider in Authentik:**
   - Type: Proxy Provider
   - Name: `[Service Name] Proxy`
   - Authorization flow: `default-provider-authorization-implicit-consent`
   - Mode: `Forward auth (single application)`
   - External host: `https://[service].example.com`
   - Cookie domain: `example.com`

2. **Create Application:**
   - Name: `[Service Name]`
   - Slug: `[service-name]`
   - Provider: Select the proxy provider created above
   - Launch URL: `https://[service].example.com`

3. **Configure Nginx:**

Add to your nginx configuration for the service:

```nix
services.nginx.virtualHosts."[service].example.com" = {
  forceSSL = true;
  sslCertificate = config.my.security.ssl.certPath;
  sslCertificateKey = config.my.security.ssl.keyPath;

  locations."/" = {
    proxyPass = "http://localhost:[port]";
    extraConfig = ''
      # Forward authentication to Authentik
      auth_request /outpost.goauthentik.io/auth/nginx;
      error_page 401 = @goauthentik_proxy_signin;

      # Pass user info to backend
      auth_request_set $auth_user $upstream_http_x_authentik_username;
      auth_request_set $auth_groups $upstream_http_x_authentik_groups;
      auth_request_set $auth_email $upstream_http_x_authentik_email;

      proxy_set_header X-authentik-username $auth_user;
      proxy_set_header X-authentik-groups $auth_groups;
      proxy_set_header X-authentik-email $auth_email;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-Host $host;
    '';
  };

  # Authentik outpost location
  locations."/outpost.goauthentik.io" = {
    proxyPass = "https://auth.example.com/outpost.goauthentik.io";
    extraConfig = ''
      proxy_set_header Host $host;
      proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
    '';
  };

  # Redirect to sign-in on 401
  locations."@goauthentik_proxy_signin" = {
    return = "302 https://auth.example.com/outpost.goauthentik.io/start?rd=$escaped_request_uri";
  };
};
```

---

### 9-14. Servarr Apps (Sonarr, Radarr, Prowlarr, Bazarr, Lidarr, Readarr)

**Important:** These apps need API endpoints accessible without authentication for inter-service communication.

**Nginx Configuration Pattern:**

```nix
services.nginx.virtualHosts."[service].example.com" = {
  forceSSL = true;
  sslCertificate = config.my.security.ssl.certPath;
  sslCertificateKey = config.my.security.ssl.keyPath;

  # API endpoints bypass authentication
  locations."~ ^/api" = {
    proxyPass = "http://localhost:[port]";
    extraConfig = ''
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    '';
  };

  # UI requires authentication
  locations."/" = {
    proxyPass = "http://localhost:[port]";
    extraConfig = ''
      auth_request /outpost.goauthentik.io/auth/nginx;
      error_page 401 = @goauthentik_proxy_signin;

      auth_request_set $auth_user $upstream_http_x_authentik_username;
      proxy_set_header X-authentik-username $auth_user;
    '';
  };

  # ... add outpost and signin locations as above ...
};
```

**Service-Specific Ports:**
- Sonarr: 8989
- Radarr: 7878
- Prowlarr: 9696
- Bazarr: 6767
- Lidarr: 8686
- Readarr: 8787

---

### 15. Transmission

**Port:** 9091
**URL:** Use LAN IP (currently `http://192.168.1.165:9091`)

Since Transmission is accessed via LAN IP, you may want to keep it on basic auth or set up a reverse proxy with authentication if you want external access.

**If exposing externally via domain:**

```nix
services.nginx.virtualHosts."transmission.example.com" = {
  forceSSL = true;
  sslCertificate = config.my.security.ssl.certPath;
  sslCertificateKey = config.my.security.ssl.keyPath;

  locations."/" = {
    proxyPass = "http://localhost:9091";
    extraConfig = ''
      auth_request /outpost.goauthentik.io/auth/nginx;
      error_page 401 = @goauthentik_proxy_signin;

      auth_request_set $auth_user $upstream_http_x_authentik_username;
      proxy_set_header X-authentik-username $auth_user;
    '';
  };

  # ... add outpost and signin locations ...
};
```

---

### 16. Homepage Dashboard

**Port:** 8082
**URL:** `https://home.example.com`

Homepage requires authentication as it exposes API keys and sensitive information.

**Nginx Configuration:**

```nix
services.nginx.virtualHosts."home.example.com" = {
  forceSSL = true;
  sslCertificate = config.my.security.ssl.certPath;
  sslCertificateKey = config.my.security.ssl.keyPath;

  locations."/" = {
    proxyPass = "http://localhost:8082";
    extraConfig = ''
      auth_request /outpost.goauthentik.io/auth/nginx;
      error_page 401 = @goauthentik_proxy_signin;

      auth_request_set $auth_user $upstream_http_x_authentik_username;
      proxy_set_header X-authentik-username $auth_user;
    '';
  };

  locations."/outpost.goauthentik.io" = {
    proxyPass = "https://auth.example.com/outpost.goauthentik.io";
    extraConfig = ''
      proxy_set_header Host $host;
      proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
    '';
  };

  locations."@goauthentik_proxy_signin" = {
    return = "302 https://auth.example.com/outpost.goauthentik.io/start?rd=$escaped_request_uri";
  };
};
```

**Note:** Currently your Homepage configuration has hardcoded SSL paths. Update to use centralized config:

```nix
services.nginx.virtualHosts."home.example.com" = {
  forceSSL = true;
  sslCertificate = config.my.security.ssl.certPath;  # Instead of hardcoded path
  sslCertificateKey = config.my.security.ssl.keyPath;
  # ... rest of configuration
};
```

---

### 17. Filebrowser

**Port:** 8880
**URL:** Not currently exposed via domain

If you want to add authentication:

```nix
# First add nginx reverse proxy
services.nginx.virtualHosts."files.example.com" = {
  forceSSL = true;
  sslCertificate = config.my.security.ssl.certPath;
  sslCertificateKey = config.my.security.ssl.keyPath;

  locations."/" = {
    proxyPass = "http://localhost:8880";
    extraConfig = ''
      auth_request /outpost.goauthentik.io/auth/nginx;
      error_page 401 = @goauthentik_proxy_signin;

      auth_request_set $auth_user $upstream_http_x_authentik_username;
      proxy_set_header X-authentik-username $auth_user;
    '';
  };

  # ... add outpost and signin locations ...
};
```

---

## Tier 4: Special Cases

### 18. Radicale (CalDAV/CardDAV)

Radicale has two authentication options with Authentik:

#### Option A: LDAP Authentication (Recommended)

**Configuration in Authentik:**

1. **Create LDAP Provider:**
   - Name: `LDAP`
   - Bind DN: `dc=ldap,dc=labhome,dc=work` (adjust as needed)
   - Base DN: `dc=ldap,dc=labhome,dc=work`
   - Search group: Select group(s) that should have access

2. **Create LDAP Outpost:**
   - Name: `LDAP Outpost`
   - Type: LDAP
   - Provider: Select LDAP provider above
   - Integration: Embedded

3. **Create Service Account (Bind User):**
   - Go to Directory > Users > Create Service Account
   - Username: `ldap-bind-user`
   - Add to appropriate group

**Configuration in NixOS:**

```nix
services.radicale = {
  enable = true;
  settings = {
    server = {
      hosts = ["127.0.0.1:5232"];
    };

    auth = {
      type = "radicale_auth_ldap";
      ldap_url = "ldap://localhost:3389";  # Authentik LDAP port
      ldap_base = "dc=ldap,dc=labhome,dc=work";
      ldap_bind_dn = "cn=ldap-bind-user,ou=users,dc=ldap,dc=labhome,dc=work";
      ldap_bind_password = config.sops.secrets.ldap_bind_password.path;
      ldap_filter = "(&(objectClass=person)(uid={username}))";
    };

    # ... rest of settings ...
  };
};

# Add LDAP auth plugin
environment.systemPackages = [ pkgs.python3Packages.radicale-auth-ldap ];

# Add secret
sops.secrets.ldap_bind_password = {
  sopsFile = ../../../secrets/authentik.yaml;
  key = "ldap_bind_password";
  owner = config.users.users.radicale.name;
  mode = "0400";
};
```

#### Option B: HTTP Remote User (Header-based)

**⚠️ Security Warning:** This method requires careful configuration to prevent header spoofing.

**Configuration in NixOS:**

```nix
services.radicale = {
  enable = true;
  settings = {
    server = {
      hosts = ["127.0.0.1:5232"];
    };

    auth = {
      type = "http_x_remote_user";
      # Radicale will trust the X-Remote-User header
    };
  };
};

# Nginx configuration with Authentik proxy
services.nginx.virtualHosts."cal.example.com" = {
  forceSSL = true;
  sslCertificate = config.my.security.ssl.certPath;
  sslCertificateKey = config.my.security.ssl.keyPath;

  locations."/" = {
    proxyPass = "http://localhost:5232";
    extraConfig = ''
      auth_request /outpost.goauthentik.io/auth/nginx;
      error_page 401 = @goauthentik_proxy_signin;

      # Pass authenticated username to Radicale
      auth_request_set $auth_user $upstream_http_x_authentik_username;
      proxy_set_header X-Remote-User $auth_user;

      # CRITICAL: Block external X-Remote-User headers
      proxy_set_header X-Remote-User "";
      proxy_set_header X-Remote-User $auth_user;
    '';
  };

  # ... add outpost and signin locations ...
};
```

**Recommendation:** Use LDAP (Option A) as it's more secure and doesn't rely on HTTP headers.

---

## Group and Role Mapping

Create the following groups in Authentik for role-based access:

### Admin Groups
- `Homeserver Admins` - Full access to all services
- `Grafana Admins` - Admin role in Grafana
- `Media Admins` - Admin access to media services

### User Groups
- `Media Users` - Access to Jellyfin, Audiobookshelf, etc.
- `Productivity Users` - Access to Paperless, Miniflux, Radicale
- `Monitoring Users` - Access to Grafana, Homepage
- `Grafana Editors` - Editor role in Grafana

### Service Access Groups
Create specific groups for each service if you want granular control:
- `Jellyfin Users`
- `Paperless Users`
- `Sonarr Users`
- etc.

**Apply Groups to Applications:**

For each application in Authentik:
1. Go to Applications > [App Name] > Policy / Group / User Bindings
2. Bind appropriate groups
3. Set policy order

---

## Implementation Checklist

### Phase 1: Easy Wins (Native OIDC)
- [ ] Grafana
- [ ] Audiobookshelf
- [ ] Paperless-ngx
- [ ] Miniflux
- [ ] Kavita
- [ ] Jellyseerr

### Phase 2: Plugin Installation
- [ ] Install Jellyfin SSO plugin
- [ ] Configure Jellyfin OIDC
- [ ] Install HACS integration for Home Assistant
- [ ] Configure Home Assistant OIDC

### Phase 3: Proxy Authentication
- [ ] Create proxy providers for all Servarr apps
- [ ] Update nginx configurations with auth_request
- [ ] Test API endpoint exceptions
- [ ] Configure Homepage proxy auth
- [ ] Configure Transmission proxy auth (if exposing)
- [ ] Configure Filebrowser proxy auth (if exposing)

### Phase 4: Special Configuration
- [ ] Set up LDAP provider and outpost for Radicale
- [ ] Configure Radicale LDAP authentication

### Phase 5: Testing
- [ ] Test login flow for each service
- [ ] Verify group/role mappings work
- [ ] Test API endpoints for Servarr apps
- [ ] Verify mobile app access (Audiobookshelf, Jellyfin)
- [ ] Test logout and session management

---

## Troubleshooting

### Common Issues

**Issue: Redirect URI mismatch**
- Verify the redirect URI in Authentik exactly matches what the application expects
- Check for trailing slashes - some apps require them, others don't
- Ensure protocol (http/https) matches

**Issue: API calls failing for *arr apps**
- Make sure `/api` paths bypass authentication in nginx
- Use regex match: `location ~ ^/api`
- Verify other services can reach API endpoints

**Issue: "Invalid token" or "Token expired"**
- Check system time synchronization (NTP)
- Verify token lifetime settings in Authentik provider
- Clear browser cookies and try again

**Issue: Users not auto-created**
- Check "Allow users to sign up" or equivalent setting in application
- Verify email claim is being passed correctly
- Check application logs for specific errors

**Issue: Groups/roles not syncing**
- Verify `groups` scope is included in provider
- Check group claim name matches what application expects
- Review role attribute path in Grafana configuration

**Issue: Infinite redirect loop**
- Verify root_url/base_url matches actual access URL
- Check cookie domain settings
- Ensure reverse proxy is passing correct headers

**Issue: Home Assistant OIDC not working**
- Verify users exist before attempting OIDC login
- Check SSL certificate validity
- Ensure "Public Client" is selected in Authentik
- Review Home Assistant logs for specific errors

**Issue: Radicale LDAP authentication failing**
- Verify LDAP outpost is running
- Check bind user credentials
- Test LDAP connection with ldapsearch
- Review LDAP filter syntax

### Debug Mode

Enable debug logging in Authentik:
1. Go to System > Settings
2. Set log level to "debug"
3. Review logs in System > Logs

Check application-specific logs:
```bash
# Systemd service logs
journalctl -u [service-name] -f

# Nginx error logs
tail -f /var/log/nginx/error.log
```

### Testing OIDC Flow

Use Authentik's built-in test tool:
1. Go to Applications > [App Name]
2. Click "Launch" to test the flow
3. Check redirect URI handling
4. Verify token claims in Authentik logs

---

## Security Best Practices

1. **Use HTTPS Everywhere**: Ensure all services are behind SSL
2. **Rotate Secrets Regularly**: Update client secrets periodically
3. **Implement Group-Based Access**: Don't give everyone access to everything
4. **Monitor Access Logs**: Review Authentik logs for suspicious activity
5. **Use Strong Passwords**: Enforce password policies in Authentik
6. **Enable 2FA**: Require two-factor authentication for admin accounts
7. **Validate Headers**: When using proxy auth, ensure headers can't be spoofed
8. **API Key Protection**: Protect API endpoints for Servarr apps appropriately
9. **Session Timeout**: Configure appropriate session durations
10. **Backup Configuration**: Keep encrypted backups of secrets and configs

---

## Additional Resources

- [Authentik Documentation](https://docs.goauthentik.io/)
- [Authentik Integrations](https://docs.goauthentik.io/integrations/)
- [OAuth2/OIDC Debugging](https://oauth.tools/)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)

---

## Maintenance

### Regular Tasks

**Monthly:**
- Review access logs for unusual activity
- Check for Authentik updates
- Verify backups are working

**Quarterly:**
- Rotate client secrets
- Review and update group memberships
- Audit user accounts (remove inactive users)

**Annually:**
- Review and update security policies
- Update authentication flow customizations
- Review and optimize session settings

---

## Notes

- This configuration assumes all services are on the same domain (`example.com`)
- Adjust ports and URLs according to your actual setup
- Some services may require application restart after OIDC configuration
- Keep client secrets in SOPS-encrypted files
- Test each integration thoroughly before moving to production
- Consider implementing rate limiting at the reverse proxy level
- Monitor certificate expiration for SSL certificates

---

*Last updated: 2025-11-10*
