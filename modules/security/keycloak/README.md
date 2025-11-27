# Keycloak Identity and Access Management

This module configures Keycloak as a centralized identity and access management solution for all your services.

## Features

- **Keycloak**: Open-source identity provider with OpenID Connect / OAuth 2.0
- **OAuth2 Proxy**: Transparent authentication gateway for all services
- **PostgreSQL Database**: Secure credential storage
- **Nginx auth_request**: Seamless authentication integration
- **Security Hardening**: Systemd security features and resource limits
- **SOPS Integration**: Encrypted secrets management

## Architecture

```
User Browser
     ↓
[Nginx Reverse Proxy]
     ↓
[auth_request → OAuth2 Proxy] ← validates with → [Keycloak]
     ↓ (if authenticated)                              ↑
[Backend Service]                                       |
  - Homepage                                     [PostgreSQL]
  - Kavita                                       (user database)
  - Microbin
  - Miniflux
  - Jellyfin & Arr Suite
  - etc.
```

## Quick Links

- **[Quick Start Guide](QUICK-START.md)** - Get started in minutes
- **[Complete Setup Guide](SETUP.md)** - Detailed configuration instructions
- **[Secrets Template](SECRETS-TEMPLATE.md)** - Required secrets reference

## Protected Services

All services except `atuin_server` are protected with Keycloak authentication:

### ✅ Protected (13 services)
- Homepage Dashboard (`home.${domain}`)
- Kavita (`kavita.${domain}`)
- Microbin (`microbin.${domain}`)
- Miniflux (`miniflux.${domain}`)
- Jellyfin (`jellyfin.${domain}`)
- Jellyseerr (`jellyseerr.${domain}`)
- Audiobookshelf (`audiobookshelf.${domain}`)
- Sonarr, Radarr, Prowlarr, Bazarr, Lidarr, Readarr

### ❌ Excluded
- Atuin Server (by request)
- Grafana (uses native Keycloak OAuth integration)

## Setup Instructions

### 1. Add Secrets to keycloak.yaml

Edit the encrypted secrets file:

```bash
cd /home/zeev/src/nix-config
sops secrets/keycloak.yaml
```

Add the following key (admin_password already exists):

```yaml
keycloak_admin_password: your-secure-admin-password
db_password: your-secure-database-password
```

Generate a secure database password:
```bash
openssl rand -base64 32
```

### 2. Enable the Module

The module is already imported in [modules/services/default.nix](../default.nix).

### 3. Rebuild and Deploy

```bash
sudo nixos-rebuild switch --flake .#your-hostname
```

### 4. Access Keycloak

- URL: `https://auth.${config.my.defaults.domain}`
- Username: `admin`
- Password: The password set in `keycloak_admin_password`

## Integrating Services with Keycloak

### Example: Grafana with OAuth

Update your Grafana configuration to use Keycloak OAuth:

```nix
"auth.generic_oauth" = {
  enabled = true;
  name = "Keycloak";
  client_id = "grafana";
  client_secret = "$__file{${config.sops.secrets.grafana_oauth_secret.path}}";
  scopes = "openid profile email";
  auth_url = "https://auth.${config.my.defaults.domain}/realms/master/protocol/openid-connect/auth";
  token_url = "https://auth.${config.my.defaults.domain}/realms/master/protocol/openid-connect/token";
  api_url = "https://auth.${config.my.defaults.domain}/realms/master/protocol/openid-connect/userinfo";
  role_attribute_path = "contains(groups, 'Grafana Admins') && 'Admin' || contains(groups, 'Grafana Editors') && 'Editor' || 'Viewer'";
  allow_sign_up = true;
};
```

### Setting up OAuth Clients in Keycloak

1. Log in to Keycloak admin console at `https://auth.${config.my.defaults.domain}`
2. Navigate to **Clients** → **Create Client**
3. Configure:
   - **Client ID**: `grafana` (or your service name)
   - **Client Type**: `OpenID Connect`
   - **Client authentication**: `On` (for confidential clients)
4. Click **Next**, then configure:
   - **Valid Redirect URIs**: `https://your-service.domain/*`
   - **Web Origins**: `https://your-service.domain`
5. Save and note the **Client Secret** from the **Credentials** tab
6. Add the client secret to SOPS secrets

### Common OAuth Endpoints

For the `master` realm:
- **Authorization**: `https://auth.${domain}/realms/master/protocol/openid-connect/auth`
- **Token**: `https://auth.${domain}/realms/master/protocol/openid-connect/token`
- **UserInfo**: `https://auth.${domain}/realms/master/protocol/openid-connect/userinfo`
- **Logout**: `https://auth.${domain}/realms/master/protocol/openid-connect/logout`

Replace `master` with your custom realm name if you create one.

## Creating a Custom Realm

Instead of using the default `master` realm, it's recommended to create a dedicated realm:

1. Log in to Keycloak admin console
2. Click the realm dropdown (top left) → **Create Realm**
3. Enter a realm name (e.g., `homelab`)
4. Create users, groups, and roles in this realm
5. Update service OAuth URLs to use the new realm name

## User Management

### Creating Users

1. Select your realm
2. Navigate to **Users** → **Add user**
3. Fill in user details
4. Click **Create**
5. Go to **Credentials** tab → **Set password**
6. Optionally disable **Temporary** password requirement

### Creating Groups and Roles

1. **Groups**: Navigate to **Groups** → **Create group**
2. **Roles**: Navigate to **Realm roles** → **Create role**
3. Assign roles to groups or users

## Security

- Keycloak runs on localhost (127.0.0.1), only accessible via nginx reverse proxy
- All credentials stored in SOPS-encrypted files
- Systemd security hardening enabled:
  - `NoNewPrivileges`, `PrivateTmp`, `ProtectHome`, `ProtectSystem`
  - Memory limit: 2GB, CPU quota: 200%
- PostgreSQL database with encrypted passwords
- SSL/TLS termination at nginx level

## Monitoring

Keycloak exposes health and metrics endpoints:

- **Health**: `https://auth.${domain}/health`
- **Metrics**: `https://auth.${domain}/metrics`

You can add these to your Prometheus configuration:

```nix
scrapeConfigs = [
  {
    job_name = "keycloak";
    static_configs = [{
      targets = ["localhost:8080"];
    }];
    metrics_path = "/metrics";
  }
];
```

## Backup

The Keycloak data directory (`/var/lib/keycloak`) is automatically included in borgmatic backups.

## Troubleshooting

### Check Keycloak Service Status

```bash
sudo systemctl status keycloak.service
sudo journalctl -u keycloak.service -f
```

### Check Database Connection

```bash
# Check PostgreSQL is running
sudo systemctl status postgresql.service

# Connect to Keycloak database
sudo -u postgres psql -d keycloak
```

### View Logs

```bash
# View live logs
sudo journalctl -u keycloak.service -f

# View last 100 lines
sudo journalctl -u keycloak.service -n 100
```

### Common Issues

**Issue**: Keycloak fails to start
- Check database is running: `sudo systemctl status postgresql.service`
- Check database password is correct in secrets
- View logs for specific error

**Issue**: Cannot access admin console
- Verify nginx is running: `sudo systemctl status nginx.service`
- Check SSL certificates are valid
- Ensure firewall allows port 8080 or nginx port

**Issue**: OAuth login fails
- Verify client configuration in Keycloak matches service config
- Check redirect URIs are correctly configured
- Ensure client secret matches in both Keycloak and service

## Advanced Configuration

### Custom Themes

Place custom themes in `/var/lib/keycloak/themes/`:

```nix
services.keycloak.themes = {
  my-theme = pkgs.fetchFromGitHub {
    owner = "example";
    repo = "keycloak-theme";
    rev = "v1.0.0";
    sha256 = "...";
  };
};
```

### Event Listeners

To add custom event listeners (e.g., for logging or notifications), you can create a custom Keycloak provider:

1. Implement `org.keycloak.events.EventListenerProvider`
2. Package as a JAR
3. Deploy to Keycloak's providers directory
4. Enable via admin console

## References

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Keycloak on NixOS](https://search.nixos.org/options?query=services.keycloak)
- [OpenID Connect Specification](https://openid.net/connect/)
- [OAuth 2.0 Specification](https://oauth.net/2/)
