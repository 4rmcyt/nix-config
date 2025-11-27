# Keycloak Authentication Setup Guide

This guide will walk you through setting up Keycloak authentication for all your services.

## Architecture Overview

The authentication system uses:
- **Keycloak**: Identity provider and user management
- **OAuth2 Proxy**: Authentication gateway for services without native OIDC support
- **Nginx auth_request**: Transparent authentication layer

## Step 1: Add Required Secrets

Edit the Keycloak secrets file:

```bash
cd /home/zeev/src/nix-config
sops secrets/keycloak.yaml
```

Add the following keys:

```yaml
keycloak_admin_password: your-secure-admin-password
oauth2_proxy_client_secret: your-oauth2-proxy-client-secret
oauth2_proxy_cookie_secret: your-cookie-secret-base64
```

### Generate Secrets

```bash
# Database password (32 characters)
openssl rand -base64 32

# OAuth2 Proxy client secret (32 characters)
openssl rand -base64 32

# OAuth2 Proxy cookie secret (32 bytes, base64 encoded)
openssl rand -base64 32 | head -c 32 | base64
```

## Step 2: Deploy Keycloak

Rebuild your NixOS configuration:

```bash
sudo nixos-rebuild switch --flake .#your-hostname
```

Wait for Keycloak to start:

```bash
sudo systemctl status keycloak.service
sudo journalctl -u keycloak.service -f
```

## Step 3: Initial Keycloak Setup

### Access Keycloak Admin Console

1. Navigate to `https://auth.${your-domain}`
2. Log in with:
   - Username: `admin`
   - Password: `${keycloak_admin_password}`

### Create a Custom Realm (Recommended)

Instead of using the `master` realm for your services:

1. Click the realm dropdown (top left) → **Create Realm**
2. Realm name: `homelab` (or your preferred name)
3. Click **Create**

## Step 4: Create OAuth2 Proxy Client in Keycloak

This client allows OAuth2 Proxy to authenticate users for all services.

1. Navigate to **Clients** → **Create client**
2. Configure:
   - **Client type**: `OpenID Connect`
   - **Client ID**: `oauth2-proxy`
   - Click **Next**

3. **Capability config**:
   - **Client authentication**: `On`
   - **Authorization**: `Off`
   - **Standard flow**: `On` (checked)
   - **Direct access grants**: `Off`
   - Click **Next**

4. **Login settings**:
   - **Root URL**: `https://auth.${your-domain}`
   - **Valid redirect URIs**:
     ```
     https://auth.${your-domain}/oauth2/callback
     https://*.${your-domain}/oauth2/callback
     ```
   - **Valid post logout redirect URIs**: `https://*.${your-domain}/*`
   - **Web origins**: `https://*.${your-domain}`
   - Click **Save**

5. Go to the **Credentials** tab
6. Copy the **Client secret** → This is your `oauth2_proxy_client_secret`
7. Update `secrets/keycloak.yaml` with this value

## Step 5: Create Users

1. Navigate to **Users** → **Add user**
2. Fill in:
   - **Username**: your username
   - **Email**: your email (optional)
   - **First name** / **Last name**: optional
   - **Email verified**: `On` (if you provided email)
3. Click **Create**
4. Go to **Credentials** tab
5. Click **Set password**
6. Enter password and disable **Temporary**
7. Click **Save**

## Step 6: Create Groups and Roles (Optional)

### Create Groups

1. Navigate to **Groups** → **Create group**
2. Create groups like:
   - `administrators`
   - `users`
   - `media-users`

### Assign Users to Groups

1. Go to **Users** → Select user
2. Click **Groups** tab
3. Select group and click **Join**

### Create Roles

1. Navigate to **Realm roles** → **Create role**
2. Create roles like:
   - `admin`
   - `user`
   - `media-access`

### Map Roles to Groups

1. Navigate to **Groups** → Select group
2. Go to **Role mapping** tab
3. Click **Assign role**
4. Select roles to assign

## Step 7: Update OAuth2 Proxy Configuration (if using custom realm)

If you created a custom realm (e.g., `homelab` instead of `master`), update the OAuth2 Proxy configuration:

Edit [oauth2-proxy.nix](oauth2-proxy.nix) and change:

```nix
oidc-issuer-url = "https://auth.${config.my.defaults.domain}/realms/homelab";
```

## Step 8: Rebuild and Test

Rebuild your configuration:

```bash
sudo nixos-rebuild switch --flake .#your-hostname
```

Check OAuth2 Proxy is running:

```bash
sudo systemctl status oauth2-proxy.service
sudo journalctl -u oauth2-proxy.service -f
```

## Step 9: Test Authentication

1. Navigate to any protected service (e.g., `https://home.${your-domain}`)
2. You should be redirected to Keycloak login
3. Log in with your created user credentials
4. You should be redirected back to the service

## Services Protected by OAuth2 Proxy

The following services are automatically protected:

### Dashboard & Utilities
- **Homepage Dashboard** (`home.${domain}`) - Port 8082
- **Microbin** (`microbin.${domain}`) - Port 8069
- **Miniflux** (`miniflux.${domain}`) - Port 8086

### Media Library
- **Kavita** (`kavita.${domain}`) - Port 5000

### Media Management (Nixarr)
- **Jellyfin** (`jellyfin.${domain}`) - Port 8096
- **Jellyseerr** (`jellyseerr.${domain}`) - Port 5055
- **Audiobookshelf** (`audiobookshelf.${domain}`) - Port 9292

### Arr Suite
- **Sonarr** (`sonarr.${domain}`) - Port 8989
- **Radarr** (`radarr.${domain}`) - Port 7878
- **Prowlarr** (`prowlarr.${domain}`) - Port 9696
- **Bazarr** (`bazarr.${domain}`) - Port 6767
- **Lidarr** (`lidarr.${domain}`) - Port 8686
- **Readarr** (`readarr.${domain}`) - Port 8787

### Monitoring (Native OAuth)
- **Grafana** (`grafana.${domain}`) - Uses native Keycloak OAuth integration

**Note**: Atuin Server is excluded from authentication as requested.

## Troubleshooting

### OAuth2 Proxy Issues

**Check service status:**
```bash
sudo systemctl status oauth2-proxy.service
sudo journalctl -u oauth2-proxy.service -f
```

**Common issues:**
- **401 Unauthorized**: Client secret mismatch → Verify `oauth2_proxy_client_secret` in secrets matches Keycloak
- **Cookie issues**: Check `oauth2_proxy_cookie_secret` is properly base64 encoded
- **Redirect loop**: Verify redirect URIs in Keycloak client match your domain

### Keycloak Issues

**Check service status:**
```bash
sudo systemctl status keycloak.service
sudo journalctl -u keycloak.service -f
```

**Common issues:**
- **Database connection failed**: Check PostgreSQL is running and password is correct
- **Port already in use**: Another service might be using port 8080
- **Certificate errors**: Verify SSL certificates are properly configured

### Nginx Issues

**Test nginx configuration:**
```bash
sudo nginx -t
```

**Reload nginx:**
```bash
sudo systemctl reload nginx.service
```

**Check nginx logs:**
```bash
sudo journalctl -u nginx.service -f
```

### Authentication Not Working

1. **Clear browser cookies** for `*.${your-domain}`
2. **Check OAuth2 Proxy logs** for specific errors
3. **Verify client secret** matches between Keycloak and sops secrets
4. **Test direct access** to OAuth2 Proxy: `http://localhost:4180/ping`

### Cannot Access Services

1. **Verify service is running:**
   ```bash
   sudo systemctl status <service-name>
   ```

2. **Check port is listening:**
   ```bash
   ss -tlnp | grep <port>
   ```

3. **Test without authentication** by temporarily commenting out auth_request in nginx-auth.nix

## Advanced Configuration

### Per-Service Authorization

To restrict specific services to specific groups/roles:

1. **Create service-specific clients** in Keycloak instead of using one OAuth2 Proxy
2. **Use client roles** and assign to users/groups
3. **Configure audience restrictions** in OAuth2 Proxy

### Custom Login Page

To customize the Keycloak login page:

1. Create a custom theme
2. Place in `/var/lib/keycloak/themes/`
3. Update Keycloak realm settings

### Session Duration

To adjust session length:

1. In Keycloak Admin Console
2. Navigate to **Realm Settings** → **Sessions**
3. Configure:
   - **SSO Session Idle**: Time before session expires due to inactivity
   - **SSO Session Max**: Maximum session lifetime
   - **Access Token Lifespan**: How long tokens are valid

### API Access

Some services need API keys for automation. To allow both OAuth and API key access:

Edit the nginx configuration to skip auth for API endpoints:

```nix
locations."/api/" = {
  proxyPass = "http://localhost:<port>/api/";
  # No auth_request for API endpoints
};
```

## Updating Secrets

If you need to rotate secrets:

### Rotate OAuth2 Proxy Client Secret

1. Edit Keycloak client credentials → **Regenerate Secret**
2. Update `secrets/keycloak.yaml` with new secret
3. Rebuild: `sudo nixos-rebuild switch --flake .#your-hostname`
4. Restart OAuth2 Proxy: `sudo systemctl restart oauth2-proxy.service`

### Rotate Cookie Secret

1. Generate new secret: `openssl rand -base64 32 | head -c 32 | base64`
2. Update `secrets/keycloak.yaml`
3. Rebuild and restart
4. **All users will be logged out** and need to re-authenticate

## Backup and Recovery

### Backup Keycloak Data

Keycloak data is stored in PostgreSQL database `keycloak`. This is automatically backed up via borgmatic.

### Manual Export

To export realm configuration:

1. Navigate to **Realm Settings** → **Action** → **Partial export**
2. Select what to export (users, clients, roles, etc.)
3. Click **Export**

### Restore from Backup

1. Restore PostgreSQL database from borgmatic backup
2. Restart Keycloak: `sudo systemctl restart keycloak.service`

## Security Best Practices

1. **Use strong passwords** for Keycloak admin account
2. **Enable 2FA** in Keycloak for admin users (Configure → Authentication → Required Actions)
3. **Regularly rotate secrets** (client secrets, cookie secrets)
4. **Monitor failed login attempts** via Keycloak admin console → Events
5. **Review user sessions** regularly and revoke suspicious ones
6. **Keep Keycloak updated** via NixOS updates
7. **Use custom realm** instead of master realm for production
8. **Backup realm configuration** regularly

## References

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [OAuth2 Proxy Documentation](https://oauth2-proxy.github.io/oauth2-proxy/)
- [OpenID Connect Specification](https://openid.net/connect/)
- [Nginx auth_request Module](https://nginx.org/en/docs/http/ngx_http_auth_request_module.html)
