# Keycloak Authentication - Quick Start Guide

This is a condensed quick-start guide. For detailed information, see [SETUP.md](SETUP.md).

## Overview

Keycloak now provides authentication for all your services except `atuin_server`:

✅ **Protected Services** (13 total):
- Homepage Dashboard, Kavita, Microbin, Miniflux
- Jellyfin, Jellyseerr, Audiobookshelf
- Sonarr, Radarr, Prowlarr, Bazarr, Lidarr, Readarr

❌ **Excluded**:
- Atuin Server (as requested)
- Grafana (uses native Keycloak OAuth, configured separately)

## Installation Steps

### 1. Generate Secrets

```bash
# Generate all secrets at once
echo "keycloak_admin_password: $(openssl rand -base64 32)"
echo "db_password: $(openssl rand -base64 32)"
echo "oauth2_proxy_cookie_secret: $(openssl rand -base64 32 | head -c 32 | base64)"
```

### 2. Add Secrets to SOPS

```bash
cd /home/zeev/src/nix-config
sops secrets/keycloak.yaml
```

Add the three secrets generated above. Leave `oauth2_proxy_client_secret` empty for now.

### 3. First Deployment (Keycloak Only)

Temporarily disable OAuth2 Proxy to set up Keycloak first:

Edit `modules/services/keycloak/default.nix`:

```nix
imports = [
  # ./oauth2-proxy.nix  # Comment this out for now
  # ./nginx-auth.nix    # Comment this out for now
];
```

Deploy:

```bash
sudo nixos-rebuild switch --flake .#your-hostname
```

### 4. Configure Keycloak

1. Access: `https://auth.${your-domain}`
2. Login: username `admin`, password from `keycloak_admin_password`
3. Create OAuth2 Proxy client:
   - Go to **Clients** → **Create client**
   - Client ID: `oauth2-proxy`
   - Client type: `OpenID Connect`
   - Client authentication: `On`
   - Valid redirect URIs:
     ```
     https://auth.${your-domain}/oauth2/callback
     https://*.${your-domain}/oauth2/callback
     ```
   - Web origins: `https://*.${your-domain}`
   - Save
4. Copy **Client Secret** from **Credentials** tab
5. Create at least one user:
   - **Users** → **Add user**
   - Set username/email
   - **Credentials** tab → Set password (disable temporary)

### 5. Add OAuth2 Client Secret

```bash
sops secrets/keycloak.yaml
```

Add the client secret you copied:

```yaml
oauth2_proxy_client_secret: <paste-client-secret-here>
```

### 6. Second Deployment (Full Stack)

Uncomment the imports in `modules/services/keycloak/default.nix`:

```nix
imports = [
  ./oauth2-proxy.nix
  ./nginx-auth.nix
];
```

Deploy:

```bash
sudo nixos-rebuild switch --flake .#your-hostname
```

### 7. Test

Navigate to any service (e.g., `https://home.${your-domain}`). You should:
1. Be redirected to Keycloak login
2. Enter credentials
3. Be redirected back to the service

## Quick Troubleshooting

### Service won't start
```bash
# Check logs
sudo journalctl -u keycloak.service -f
sudo journalctl -u oauth2-proxy.service -f
sudo journalctl -u nginx.service -f
```

### Authentication not working
- Clear browser cookies for `*.${your-domain}`
- Verify client secret matches between Keycloak and secrets file
- Check OAuth2 Proxy logs: `sudo journalctl -u oauth2-proxy.service -f`

### Can't access Keycloak admin
- Verify the service is running: `sudo systemctl status keycloak.service`
- Check nginx config: `sudo nginx -t`
- Access directly via localhost: `curl http://localhost:8080`

## File Structure

```
modules/services/keycloak/
├── default.nix          # Main Keycloak service configuration
├── oauth2-proxy.nix     # OAuth2 Proxy configuration
├── nginx-auth.nix       # Nginx authentication layer
├── README.md            # General information
├── SETUP.md             # Detailed setup guide
├── SECRETS-TEMPLATE.md  # Secrets reference
└── QUICK-START.md       # This file
```

## Next Steps

- **Create additional users**: Keycloak Admin → Users → Add user
- **Set up groups/roles**: Keycloak Admin → Groups / Realm roles
- **Customize login page**: Create custom theme
- **Enable 2FA**: Authentication → Required Actions → Configure OTP
- **Monitor logins**: Events → Login events

For detailed information, see:
- [SETUP.md](SETUP.md) - Complete setup guide
- [SECRETS-TEMPLATE.md](SECRETS-TEMPLATE.md) - Secrets reference
- [README.md](README.md) - General documentation

## Support

If you encounter issues:

1. Check logs: `sudo journalctl -u <service> -f`
2. Review [SETUP.md](SETUP.md) troubleshooting section
3. Verify secrets are correctly set: `sops -d secrets/keycloak.yaml`
4. Test components individually (Keycloak → OAuth2 Proxy → Services)
