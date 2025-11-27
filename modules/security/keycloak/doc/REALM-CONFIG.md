# Keycloak Realm Configuration

This document describes the declarative realm configuration for Keycloak.

## Overview

The `realm.nix` module automatically creates and configures a **homelab** realm with pre-configured clients, roles, groups, and security settings. This eliminates the need for manual realm setup through the admin console.

## Features

The realm configuration includes:

- **Custom Realm**: `homelab` realm (separate from the `master` admin realm)
- **OAuth2 Clients**: Pre-configured clients for OAuth2 Proxy and Grafana
- **Roles**: User, admin, and Grafana-specific roles
- **Groups**: Users, Admins, and Grafana role groups
- **Security**: Brute force protection, session management, and security headers
- **Automatic Import**: Systemd service that imports/updates realm on boot

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Keycloak (localhost:9000)                                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐      ┌────────────────────────────┐      │
│  │ Master Realm │      │ Homelab Realm              │      │
│  │              │      │                             │      │
│  │ - Admin user │      │ Clients:                   │      │
│  │              │      │  - oauth2-proxy            │      │
│  └──────────────┘      │  - grafana                 │      │
│                        │                             │      │
│                        │ Roles:                      │      │
│                        │  - user                     │      │
│                        │  - admin                    │      │
│                        │  - grafana-admin/editor    │      │
│                        │                             │      │
│                        │ Groups:                     │      │
│                        │  - Users                    │      │
│                        │  - Admins                   │      │
│                        │  - Grafana Admins/Editors  │      │
│                        └────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

## Realm Details

### Realm Name

- **Name**: `homelab`
- **Display Name**: "Homelab Services"

### Session Settings

- **SSO Session Idle Timeout**: 30 minutes
- **SSO Session Max Lifespan**: 10 hours
- **Access Token Lifespan**: 5 minutes
- **Refresh Token**: Available for extending sessions

### Security Settings

- **Brute Force Protection**: Enabled
  - Max login failures: 30
  - Lockout duration: 15 minutes (900 seconds)
  - Quick login check: 1 second
- **Password Reset**: Enabled
- **Username Editing**: Disabled (improves security)
- **Email Required**: Yes
- **Duplicate Emails**: Not allowed

## Pre-configured Clients

### 1. OAuth2 Proxy Client

**Purpose**: Provides authentication for all services behind OAuth2 Proxy

**Configuration**:
- **Client ID**: `oauth2-proxy`
- **Client Type**: Confidential
- **Protocol**: OpenID Connect
- **Redirect URIs**:
  - `https://auth.${domain}/oauth2/callback`
  - `https://*.${domain}/oauth2/callback`
- **Scopes**: `profile`, `email`, `roles`
- **PKCE**: Enabled (S256)

**Secret**: Set to `PLACEHOLDER_OAUTH2_PROXY_SECRET` - must be updated via:
1. Keycloak admin console, or
2. SOPS secrets with automatic rotation script

### 2. Grafana Client

**Purpose**: Provides OAuth authentication for Grafana

**Configuration**:
- **Client ID**: `grafana`
- **Client Type**: Confidential
- **Protocol**: OpenID Connect
- **Redirect URIs**: `https://grafana.${domain}/*`
- **Scopes**: `profile`, `email`, `roles`
- **Protocol Mappers**:
  - Groups mapper (includes user groups in tokens)

**Secret**: Set to `PLACEHOLDER_GRAFANA_SECRET` - must be updated via admin console

## Roles

### Realm Roles

| Role | Description | Purpose |
|------|-------------|---------|
| `user` | Basic user role | Default role for all authenticated users |
| `admin` | Administrator role | Full access to all services |
| `grafana-admin` | Grafana administrator | Admin access to Grafana |
| `grafana-editor` | Grafana editor | Edit dashboards in Grafana |
| `grafana-viewer` | Grafana viewer | Read-only access to Grafana |

## Groups

### Pre-configured Groups

| Group | Roles | Purpose |
|-------|-------|---------|
| `Users` | `user` | Default group for regular users |
| `Admins` | `admin`, `user` | Administrator group |
| `Grafana Admins` | `grafana-admin` | Grafana administrators |
| `Grafana Editors` | `grafana-editor` | Grafana editors |

## Automatic Import Process

The realm configuration is automatically imported/updated on system boot via the `keycloak-realm-import.service`.

### Import Process

1. Wait for Keycloak to be ready (health check)
2. Authenticate using admin credentials
3. Check if `homelab` realm exists
4. If exists: Update realm configuration
5. If not exists: Create new realm

### Systemd Service

```bash
# Check import service status
sudo systemctl status keycloak-realm-import.service

# View import logs
sudo journalctl -u keycloak-realm-import.service

# Manually trigger import
sudo systemctl restart keycloak-realm-import.service
```

## Configuration Options

The realm module exposes several options that can be used by other modules:

```nix
config.my.keycloak = {
  realm = "homelab";
  authUrl = "https://auth.${domain}/realms/homelab/protocol/openid-connect/auth";
  tokenUrl = "https://auth.${domain}/realms/homelab/protocol/openid-connect/token";
  userInfoUrl = "https://auth.${domain}/realms/homelab/protocol/openid-connect/userinfo";
  logoutUrl = "https://auth.${domain}/realms/homelab/protocol/openid-connect/logout";
};
```

### Example: Using in Grafana Configuration

```nix
services.grafana.settings."auth.generic_oauth" = {
  enabled = true;
  name = "Keycloak";
  client_id = "grafana";
  client_secret = "$__file{${config.sops.secrets.grafana_oauth_secret.path}}";
  scopes = "openid profile email";
  auth_url = config.my.keycloak.authUrl;
  token_url = config.my.keycloak.tokenUrl;
  api_url = config.my.keycloak.userInfoUrl;
  role_attribute_path = "contains(groups, 'Grafana Admins') && 'Admin' || contains(groups, 'Grafana Editors') && 'Editor' || 'Viewer'";
  allow_sign_up = true;
};
```

## Setup Instructions

### 1. Enable the Realm Configuration

The realm configuration is automatically imported when you import the main Keycloak module:

```nix
# Already included in default.nix
imports = [
  ./oauth2-proxy.nix
  ./nginx-auth.nix
  ./realm.nix  # <-- Realm configuration
];
```

### 2. Deploy the Configuration

```bash
sudo nixos-rebuild switch --flake .#your-hostname
```

### 3. Update Client Secrets

After deployment, you need to update the placeholder client secrets:

#### Option A: Via Admin Console (Quick)

1. Navigate to `https://auth.${domain}`
2. Log in as admin
3. Switch to the `homelab` realm (dropdown in top-left)
4. Go to **Clients** → **oauth2-proxy** → **Credentials** tab
5. Click **Regenerate Secret**
6. Copy the secret and add to SOPS:

```bash
sops secrets/keycloak.yaml
```

Add:
```yaml
oauth2_proxy_client_secret: <generated-secret>
grafana_oauth_secret: <generated-secret>
```

#### Option B: Via CLI (Automated)

```bash
# Get OAuth2 Proxy client secret
kcadm.sh get clients -r homelab --fields id,clientId | \
  jq -r '.[] | select(.clientId=="oauth2-proxy") | .id' | \
  xargs -I {} kcadm.sh get clients/{}/client-secret -r homelab
```

### 4. Create Your First User

1. Log in to Keycloak admin console
2. Switch to `homelab` realm
3. Navigate to **Users** → **Add user**
4. Fill in user details:
   - Username: `your-username`
   - Email: `your-email@example.com`
   - Email verified: `On`
   - Enabled: `On`
5. Click **Create**
6. Go to **Credentials** tab
7. Click **Set password**
8. Enter password and disable "Temporary"
9. Go to **Groups** tab
10. Click **Join Group**
11. Select `Users` (or `Admins` for admin access)

### 5. Test OAuth Login

1. Navigate to any protected service (e.g., `https://home.${domain}`)
2. You should be redirected to Keycloak login
3. Log in with your created user
4. You should be redirected back to the service

## Customizing the Realm

### Modifying Realm Settings

Edit [realm.nix](realm.nix) and change the `realmConfig` variable:

```nix
realmConfig = pkgs.writeText "homelab-realm.json" (builtins.toJSON {
  realm = realmName;
  # Add or modify settings here
  ssoSessionIdleTimeout = 3600; # Change to 1 hour
  # ... more settings
});
```

### Adding New Clients

Add to the `clients` array in `realmConfig`:

```nix
clients = [
  # ... existing clients
  {
    clientId = "my-new-service";
    name = "My New Service";
    enabled = true;
    clientAuthenticatorType = "client-secret";
    secret = "PLACEHOLDER_MY_SERVICE_SECRET";
    redirectUris = [
      "https://myservice.${domain}/callback"
    ];
    webOrigins = ["https://myservice.${domain}"];
    standardFlowEnabled = true;
    protocol = "openid-connect";
    defaultClientScopes = ["profile" "email" "roles"];
  }
];
```

### Adding New Roles

Add to the `roles.realm` array:

```nix
roles = {
  realm = [
    # ... existing roles
    {
      name = "my-custom-role";
      description = "My custom role description";
    }
  ];
};
```

### Adding New Groups

Add to the `groups` array:

```nix
groups = [
  # ... existing groups
  {
    name = "My Custom Group";
    path = "/My Custom Group";
    realmRoles = ["my-custom-role" "user"];
  }
];
```

## Email Configuration

To enable password resets and email notifications, configure SMTP settings:

1. Edit [realm.nix](realm.nix)
2. Update the `smtpServer` section:

```nix
smtpServer = {
  host = "smtp.gmail.com";
  port = "587";
  from = "noreply@${domain}";
  fromDisplayName = "Homelab Auth";
  ssl = "false";
  starttls = "true";
  auth = "true";
  # Note: username/password should be set via admin console
};
```

3. Set SMTP credentials via admin console:
   - Realm Settings → Email → Connection & Authentication

## Security Best Practices

### 1. Client Secrets

- Always rotate client secrets after initial setup
- Store secrets in SOPS encrypted files
- Never commit secrets to version control

### 2. User Management

- Require strong passwords (configure in Realm Settings → Authentication → Policies)
- Enable email verification for new users
- Use groups and roles for access control

### 3. Session Management

- Keep SSO session idle timeout reasonable (30 minutes default)
- Set appropriate token lifespans (5 minutes for access tokens)
- Use refresh tokens for long-lived sessions

### 4. Brute Force Protection

Default settings should be adequate, but can be adjusted:
- Increase `failureFactor` for more lenient protection
- Decrease `maxFailureWaitSeconds` for stricter protection

## Troubleshooting

### Realm Import Failed

```bash
# Check service logs
sudo journalctl -u keycloak-realm-import.service -n 100

# Common issues:
# 1. Keycloak not started yet - increase timeout in script
# 2. Invalid JSON configuration - validate with: jq '.' realm-config.json
# 3. Admin password incorrect - verify SOPS secret
```

### Client Secret Not Working

```bash
# Retrieve current secret from Keycloak
kcadm.sh config credentials --server http://localhost:9000 \
  --realm master --user admin --password <admin-password>

kcadm.sh get clients -r homelab --fields id,clientId,secret
```

### Users Can't Log In

1. Verify user is in `homelab` realm (not `master`)
2. Check user is enabled (Users → select user → Details → Enabled)
3. Verify user has correct groups/roles
4. Check brute force protection hasn't locked the account

### Realm Not Updating

```bash
# Force realm import
sudo systemctl restart keycloak-realm-import.service

# If still not updating, manually update via CLI:
kcadm.sh update realms/homelab -f /path/to/realm-config.json
```

## Advanced Topics

### Realm Export

To export the current realm configuration:

```bash
kcadm.sh config credentials --server http://localhost:9000 \
  --realm master --user admin

kcadm.sh get realms/homelab > homelab-realm-export.json
```

### Importing Users Bulk

Create a users JSON file and import:

```bash
kcadm.sh create users -r homelab -f users-import.json
```

### Custom Authentication Flows

Modify the realm configuration to add custom authentication flows:

```nix
authenticationFlows = [
  {
    alias = "browser-with-mfa";
    providerId = "basic-flow";
    topLevel = true;
    # ... authentication flow configuration
  }
];
```

## References

- [Keycloak Server Admin](https://www.keycloak.org/docs/latest/server_admin/)
- [Keycloak Admin CLI](https://www.keycloak.org/docs/latest/server_admin/#the-admin-cli)
- [Realm Configuration](https://www.keycloak.org/docs/latest/server_admin/#_export_import)
- [NixOS Keycloak Options](https://search.nixos.org/options?query=services.keycloak)
