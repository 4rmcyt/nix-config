# Keycloak OIDC Integration Guide for Services

This guide explains how to configure Keycloak OIDC authentication for your services after deploying Keycloak to k3s.

## Overview

Keycloak is now deployed in k3s and accessible at `https://auth.example.com`. It will provide OAuth2/OIDC authentication for:
- Homepage
- Kavita
- Miniflux
- Nixarr (Sonarr, Radarr, etc.)
- Atuin Server
- Microbin

## Step 1: Initial Keycloak Setup

### 1.1 Create Kubernetes Secret

First, create the secret with your credentials:

```bash
kubectl create secret generic keycloak-secrets \
  --from-literal=db-password='<strong-db-password>' \
  --from-literal=admin-password='<strong-admin-password>'
```

### 1.2 Deploy Keycloak

After rebuilding your NixOS configuration, Keycloak will be deployed to k3s. Verify it's running:

```bash
kubectl get pods
kubectl get services
```

### 1.3 Access Keycloak Admin Console

Navigate to `https://auth.example.com` and log in with:
- Username: `admin`
- Password: The password you set in the kubernetes secret

## Step 2: Create Realm

1. Click "Create Realm" in the top-left dropdown
2. Name: `homelab` (or your preferred name)
3. Enable: Yes
4. Click "Create"

## Step 3: Configure OIDC Clients

For each service, create an OIDC client:

### 3.1 Homepage Dashboard

1. Go to Clients → Create Client
2. Client type: `OpenID Connect`
3. Client ID: `homepage`
4. Click "Next"
5. Client authentication: ON
6. Authorization: OFF
7. Authentication flow:
   - Standard flow: ✓
   - Direct access grants: ✓
8. Click "Next", then "Save"
9. Settings tab:
   - Root URL: `https://home.example.com`
   - Valid redirect URIs: `https://home.example.com/*`
   - Web origins: `https://home.example.com`
10. Click "Save"
11. Credentials tab → Copy the "Client secret"

### 3.2 Kavita

1. Go to Clients → Create Client
2. Client ID: `kavita`
3. Follow same steps as Homepage
4. Settings:
   - Root URL: `https://kavita.example.com`
   - Valid redirect URIs: `https://kavita.example.com/*`
   - Web origins: `https://kavita.example.com`

### 3.3 Miniflux

1. Client ID: `miniflux`
2. Settings:
   - Root URL: `https://miniflux.example.com`
   - Valid redirect URIs:
     - `https://miniflux.example.com/oauth2/oidc/callback`
   - Web origins: `https://miniflux.example.com`

### 3.4 Atuin Server

1. Client ID: `atuin`
2. Settings:
   - Root URL: `https://atuin.example.com`
   - Valid redirect URIs: `https://atuin.example.com/*`
   - Web origins: `https://atuin.example.com`

### 3.5 Microbin

1. Client ID: `microbin`
2. Settings:
   - Root URL: `https://microbin.example.com`
   - Valid redirect URIs: `https://microbin.example.com/*`
   - Web origins: `https://microbin.example.com`

### 3.6 Nixarr Services (Sonarr, Radarr, Prowlarr, etc.)

For *arr apps, you'll need to use an auth proxy since they don't natively support OIDC.

**Option 1: Use oauth2-proxy** (Already configured in your setup)
- The existing oauth2-proxy configuration can be extended
- Each service gets protected by the proxy

**Option 2: Keycloak Gatekeeper/Louketo**
- Deploy as a sidecar

## Step 4: Configure Services

### 4.1 Miniflux

Miniflux has native OIDC support. Update your configuration:

```nix
services.miniflux = {
  config = {
    # ... existing config ...
    OAUTH2_PROVIDER = "oidc";
    OAUTH2_CLIENT_ID = "miniflux";
    OAUTH2_CLIENT_SECRET = "<client-secret-from-keycloak>";
    OAUTH2_REDIRECT_URL = "https://miniflux.example.com/oauth2/oidc/callback";
    OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://auth.example.com/realms/homelab";
  };
};
```

### 4.2 Kavita

Kavita supports OIDC authentication:

1. In Kavita UI: Settings → Authentication
2. Enable "Authentication via External Provider"
3. Configure:
   - Provider: OpenID Connect
   - Authority: `https://auth.example.com/realms/homelab`
   - Client ID: `kavita`
   - Client Secret: `<from-keycloak>`

### 4.3 Homepage Dashboard

Homepage doesn't have built-in OAuth, but you can:

**Option 1**: Use oauth2-proxy to protect the entire service
**Option 2**: Use Keycloak's application protection features

### 4.4 Atuin Server

Check Atuin documentation for OIDC support or use oauth2-proxy.

### 4.5 Microbin

Microbin may need oauth2-proxy protection.

## Step 5: Using oauth2-proxy for Services Without Native OIDC

For services that don't support OIDC natively, you can use oauth2-proxy:

### 5.1 Create oauth2-proxy client in Keycloak

1. Client ID: `oauth2-proxy`
2. Valid redirect URIs:
   - `https://oauth2-proxy.example.com/oauth2/callback`
   - `https://*.example.com/oauth2/callback`
3. Web origins: `https://*.example.com`

### 5.2 Update oauth2-proxy configuration

```nix
services.oauth2-proxy = {
  provider = "keycloak-oidc";
  oidcIssuerUrl = "https://auth.example.com/realms/homelab";
  # Update secrets file with new client ID and secret
};
```

### 5.3 Configure nginx for protected services

Add authentication to services via nginx:

```nix
services.nginx.virtualHosts."service.example.com" = {
  locations."/oauth2/" = {
    proxyPass = "http://oauth2-proxy";
  };

  locations."/" = {
    proxyPass = "http://localhost:<service-port>";
    extraConfig = ''
      auth_request /oauth2/auth;
      error_page 401 = /oauth2/sign_in;

      # Pass user info to backend
      auth_request_set $user   $upstream_http_x_auth_request_user;
      auth_request_set $email  $upstream_http_x_auth_request_email;
      proxy_set_header X-User  $user;
      proxy_set_header X-Email $email;
    '';
  };
};
```

## Step 6: User Management

### 6.1 Create Users

1. In Keycloak: Users → Add user
2. Fill in details
3. Credentials tab → Set password
4. Disable "Temporary" if you don't want forced password change

### 6.2 Groups and Roles (Optional)

1. Groups → Create group (e.g., "admins", "users")
2. Assign users to groups
3. Configure role mappings for fine-grained access control

## Step 7: Testing

1. Clear browser cookies
2. Visit each service URL
3. You should be redirected to Keycloak login
4. After login, you should be redirected back to the service

## Architecture Summary

```
User Browser
    ↓
Cloudflare Tunnel
    ↓
auth.example.com → k3s Keycloak (LoadBalancer port 9000 → container port 8080)
    ↑
    OAuth2/OIDC flows
    ↓
service.example.com → Direct or via oauth2-proxy → Service
```

## Troubleshooting

### Keycloak not accessible
```bash
kubectl logs deployment/keycloak
kubectl describe service keycloak
```

### Database connection issues
```bash
kubectl logs deployment/postgres
kubectl exec -it deployment/postgres -- psql -U keycloak -d keycloak
```

### OIDC configuration issues
- Verify redirect URIs match exactly
- Check Keycloak realm settings
- Review service logs for OAuth errors
- Ensure client secrets are correctly configured

## Security Considerations

1. **Use strong passwords** for Keycloak admin and database
2. **Enable 2FA** in Keycloak for admin accounts
3. **Regular backups** of PostgreSQL database
4. **Monitor** Keycloak logs for suspicious activity
5. **Keep Keycloak updated** for security patches
