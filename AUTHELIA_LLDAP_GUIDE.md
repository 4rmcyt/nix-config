# Authelia & LLDAP Setup Guide

Complete guide for setting up and using Authelia (SSO/2FA) and LLDAP (user management) with all configured OIDC services.

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Initial Setup](#initial-setup)
- [LLDAP User Management](#lldap-user-management)
- [Authelia Configuration](#authelia-configuration)
- [OIDC Services](#oidc-services)
- [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Components
- **LLDAP**: Lightweight LDAP server for user/group management
  - URL: `https://lldap.example.com`
  - LDAP Port: 3890
  - Web UI Port: 17170

- **Authelia**: Authentication & Authorization server with SSO and 2FA
  - URL: `https://auth.example.com`
  - Port: 9000 (proxied by Traefik)
  - Features: OIDC provider, TOTP 2FA, session management

- **PostgreSQL**: Authelia's database backend
  - Database: `authelia`
  - User: `authelia`
  - Connection: Unix socket with peer auth

- **Redis**: Session storage
  - Socket: `/run/redis-homeserver/redis.sock`
  - Database: 3 (dedicated for Authelia)

### Authentication Flow
1. User tries to access protected service (e.g., Jellyfin)
2. Traefik middleware redirects to Authelia
3. Authelia prompts for LDAP credentials
4. User logs in with LLDAP username/password
5. Authelia prompts for TOTP 2FA (first time: setup required)
6. Authelia creates session and redirects back to service
7. Service receives OIDC token and grants access

---

## Initial Setup

### 1. Verify Services are Running

After rebuild, check service status:

```bash
# Check LLDAP
systemctl status lldap.service
journalctl -u lldap.service -n 50

# Check Authelia
systemctl status authelia-main.service
journalctl -u authelia-main.service -n 50

# Check dependencies
systemctl status redis-homeserver.service
systemctl status postgresql.service
```

All services should show `active (running)`.

### 2. Get LLDAP Admin Password

The admin password is stored in your SOPS secrets:

```bash
sops -d nix-config/secrets/lldap.yaml | grep user_pass
```

### 3. Access LLDAP Web UI

1. Open browser: `https://lldap.example.com`
2. Login with:
   - **Username**: `admin`
   - **Password**: (from step 2)

---

## LLDAP User Management

### Create Your First User

1. Go to LLDAP Web UI → **People** tab
2. Click **Create User**
3. Fill in details:
   - **Username**: Your username (e.g., `zeev`)
   - **Email**: Your email address
   - **Display Name**: Your full name
   - **Password**: Strong password
4. Click **Create**

### Create Admin Group

Authelia requires an `admin` group for access control:

1. Go to **Groups** tab
2. Click **Create Group**
3. Fill in:
   - **Group Name**: `admin`
   - **Display Name**: `Administrators`
4. Click **Create**

### Add User to Admin Group

1. Go to **Groups** tab → Click on `admin` group
2. Click **Add Member**
3. Select your user
4. Click **Add**

### Additional Groups (Optional)

You can create more groups for granular access control:

```
users       - All regular users
admins      - System administrators
media       - Access to Jellyfin/Kavita/Audiobookshelf
monitoring  - Access to Grafana
```

To add users to groups, just repeat the "Add User to Admin Group" steps.

---

## Authelia Configuration

### Access Control Policies

Current configuration (from `modules/security/authelia/default.nix`):

```nix
# Bypass authentication for localhost
{
  domain = "*.example.com";
  policy = "bypass";
  networks = "localhost";
}

# Require one-factor auth for internal network (admin group only)
{
  domain = "*.example.com";
  policy = "one_factor";
  networks = "internal";
  subject = ["group:admin"];
}
```

**What this means**:
- Services accessed from localhost don't require auth
- Services accessed from internal network (192.168.x.x) require login
- Only users in `admin` group can access services
- Two-factor authentication (TOTP) is required after first login

### Network Definitions

Networks are defined in Traefik configuration. Check your internal network range:

```bash
ip addr show | grep inet
```

---

## OIDC Services

The following services are configured to use Authelia OIDC for authentication:

### 1. Jellyfin (Media Server)
- **URL**: `https://jellyfin.example.com`
- **Client ID**: `jellyfin`
- **Redirect URI**: `https://jellyfin.example.com/sso/OID/r/authelia`

**Setup**:
1. Access Jellyfin
2. Go to **Dashboard** → **Plugins**
3. Install **SSO Authentication** plugin
4. Configure:
   - Provider: Custom OIDC
   - Client ID: `jellyfin`
   - Client Secret: (from Authelia config - contact admin)
   - Discovery URL: `https://auth.example.com/.well-known/openid-configuration`
   - Scopes: `openid profile email groups`

### 2. Deluge (Torrent Client)
- **URL**: `https://deluge.example.com`
- **Client ID**: `deluge`
- **Redirect URI**: `https://deluge.example.com/callback`

**Note**: Deluge runs in VPN namespace for privacy. OIDC plugin may need manual configuration.

### 3. Grafana (Monitoring)
- **URL**: `https://grafana.example.com`
- **Client ID**: `grafana`
- **Redirect URI**: `https://grafana.example.com/login/generic_oauth`

**Setup**:
Grafana should auto-configure via NixOS module. Check configuration in `modules/monitoring/default.nix`.

### 4. Miniflux (RSS Reader)
- **URL**: `https://miniflux.example.com`
- **Client ID**: `miniflux`
- **Redirect URI**: `https://miniflux.example.com/oauth2/oidc/callback`

**Check config**:
```bash
grep -A 10 "oauth2" nix-config/modules/services/miniflux/default.nix
```

### 5. Kavita (eBook/Manga Reader)
- **URL**: `https://kavita.example.com`
- **Client ID**: `kavita`
- **Redirect URI**: `https://kavita.example.com/api/plugin/authenticate`

### 6. Audiobookshelf (Audiobook Server)
- **URL**: `https://audiobookshelf.example.com`
- **Client ID**: `audiobookshelf`
- **Redirect URI**: `https://audiobookshelf.example.com/auth/openid/callback`

---

## First Login Flow

### Step 1: Access a Protected Service

Try to access any OIDC-enabled service, e.g., `https://jellyfin.example.com`

### Step 2: Redirected to Authelia

You'll be redirected to: `https://auth.example.com`

### Step 3: Login with LDAP Credentials

Enter your LLDAP credentials:
- **Username**: Your LLDAP username (e.g., `zeev`)
- **Password**: Your LLDAP password

### Step 4: Setup TOTP 2FA

First time only:
1. Authelia shows QR code
2. Scan with authenticator app (Google Authenticator, Authy, 1Password, etc.)
3. Enter the 6-digit code from your app
4. Save recovery codes in a safe place

### Step 5: Access Granted

After successful authentication:
- Authelia redirects back to the service
- Service receives OIDC token
- You're logged in!

### Session Management

Sessions are stored in Redis with the following behavior:
- **Session duration**: Configurable (default: check Authelia config)
- **Remember me**: Extends session
- **Logout**: Clears session from Redis

---

## Testing OIDC Integration

### Test OIDC Endpoints

Check if Authelia OIDC discovery is working:

```bash
curl -k https://auth.example.com/.well-known/openid-configuration | jq
```

Expected output should include:
```json
{
  "issuer": "https://auth.example.com",
  "authorization_endpoint": "https://auth.example.com/api/oidc/authorization",
  "token_endpoint": "https://auth.example.com/api/oidc/token",
  "userinfo_endpoint": "https://auth.example.com/api/oidc/userinfo",
  ...
}
```

### Test LDAP Connection

From homeserver, test LDAP bind:

```bash
# Install ldapsearch if needed
nix-shell -p openldap

# Test admin bind
ldapsearch -x -H ldap://localhost:3890 \
  -D "uid=admin,ou=people,dc=labhome,dc=work" \
  -W \
  -b "dc=labhome,dc=work"
```

Enter your LLDAP admin password when prompted.

### Check User in LDAP

Search for your user:

```bash
ldapsearch -x -H ldap://localhost:3890 \
  -D "uid=admin,ou=people,dc=labhome,dc=work" \
  -W \
  -b "ou=people,dc=labhome,dc=work" \
  "(uid=zeev)"
```

---

## Troubleshooting

### Authelia Won't Start

**Check logs**:
```bash
journalctl -u authelia-main.service -n 100 --no-pager
```

**Common issues**:

1. **LDAP Invalid Credentials**:
   - Verify LLDAP admin password matches between services
   - Check: `sops -d nix-config/secrets/lldap.yaml`

2. **PostgreSQL Connection Failed**:
   - Verify PostgreSQL is running: `systemctl status postgresql`
   - Check peer authentication: User `authelia` should match DB user
   - Verify database exists: `sudo -u postgres psql -l | grep authelia`

3. **Redis Connection Permission Denied**:
   - Check authelia is in redis-homeserver group: `groups authelia`
   - Verify socket permissions: `ls -la /run/redis-homeserver/redis.sock`
   - Should show: `srw-rw---- redis-homeserver redis-homeserver`

### LLDAP Access Issues

**Cannot access Web UI**:
```bash
# Check if service is running
systemctl status lldap.service

# Check if port is listening
ss -tlnp | grep 17170

# Check firewall
sudo iptables -L -n | grep 17170
```

**LDAP bind fails**:
```bash
# Check LDAP port
ss -tlnp | grep 3890

# Test local connection
ldapsearch -x -H ldap://localhost:3890 -b "dc=labhome,dc=work"
```

### Service Won't Authenticate

**Symptoms**: Redirect loop, 401/403 errors

**Debug steps**:

1. **Check Authelia logs** during login attempt:
   ```bash
   journalctl -u authelia-main.service -f
   ```

2. **Verify user is in admin group**:
   - Login to LLDAP Web UI
   - Check Groups → admin → Members

3. **Check access control policy**:
   - Review `modules/security/authelia/default.nix`
   - Verify your network is in "internal" range

4. **Check service OIDC config**:
   - Client ID must match Authelia config
   - Redirect URI must be exact match
   - Discovery URL should be accessible

### Reset 2FA

If you lose access to your 2FA device:

1. **Option 1**: Use recovery codes (saved during setup)

2. **Option 2**: Admin reset via database:
   ```bash
   sudo -u postgres psql authelia -c \
     "DELETE FROM totp_configurations WHERE username='your_username';"
   ```

3. **Option 3**: Disable 2FA temporarily:
   - Edit `modules/security/authelia/default.nix`
   - Change `default_2fa_method = "totp"` to `""`
   - Rebuild system
   - Login and re-setup 2FA
   - Re-enable in config

### Check Secret Permissions

All secrets must be readable by the authelia user:

```bash
# On homeserver
sudo ls -la /run/secrets/ | grep -E "(authelia|lldap|redis|postgres|msmtp)"

# Should show:
# authelia secrets: owner=authelia or group-readable
# lldap_user_pass: group=lldap, readable by authelia (member of lldap group)
# redis password: group=redis, readable by authelia (member of redis group)
# postgres password: group=postgres, readable by authelia (member of postgres group)
```

Verify authelia user groups:
```bash
groups authelia
# Expected: authelia redis postgres msmtp lldap redis-homeserver
```

---

## Advanced Configuration

### Adding New OIDC Client

To add a new service to Authelia OIDC:

1. **Generate client secret**:
   ```bash
   nix-shell -p authelia
   authelia crypto hash generate pbkdf2 --password 'your-client-secret'
   ```

2. **Add to Authelia config** (`modules/security/authelia/default.nix`):
   ```nix
   {
     authorization_policy = "one_factor";
     client_id = "myservice";
     client_secret = "$pbkdf2-sha512$..."; # from step 1
     redirect_uris = ["https://myservice.example.com/callback"];
     scopes = ["openid" "profile" "email" "groups"];
   }
   ```

3. **Rebuild system**:
   ```bash
   sudo nixos-rebuild switch --flake .#homeserver
   ```

4. **Configure service** to use:
   - Discovery URL: `https://auth.example.com/.well-known/openid-configuration`
   - Client ID: `myservice`
   - Client Secret: Your plaintext secret (not the hash)

### Customizing Access Control

**Per-service policies**:
```nix
# Allow specific service without auth
{
  domain = "public.example.com";
  policy = "bypass";
}

# Require 2FA for sensitive service
{
  domain = "admin.example.com";
  policy = "two_factor";
  subject = ["group:admins"];
}

# Allow specific users
{
  domain = "personal.example.com";
  policy = "one_factor";
  subject = ["user:zeev"];
}
```

### Email Notifications

Authelia uses msmtp for sending emails (password resets, 2FA setup):

**Configuration** (already set up):
- SMTP: Gmail (smtp.gmail.com:587)
- From: `authelia@example.com`
- Password: Stored in `secrets/gmail_conf.yaml`

**Test email**:
```bash
echo "Test email" | mail -s "Authelia Test" your-email@example.com
```

---

## Security Best Practices

### Passwords
- Use strong, unique passwords for LLDAP users
- Store passwords in password manager
- Never share LDAP admin password

### 2FA
- Always enable TOTP 2FA
- Save recovery codes in secure location
- Use hardware token (YubiKey) for admin account (advanced)

### Secrets Management
- All secrets encrypted with SOPS
- Age keys stored securely
- Rotate secrets periodically:
  ```bash
  # Generate new secret
  openssl rand -base64 32

  # Update in SOPS
  sops nix-config/secrets/authelia.yaml
  ```

### Session Security
- Sessions stored in Redis (encrypted)
- Automatic expiration after inactivity
- Logout clears session immediately

### Access Control
- Principle of least privilege
- Create separate groups for different access levels
- Regularly audit group memberships in LLDAP

---

## Quick Reference

### URLs
| Service | URL |
|---------|-----|
| LLDAP | https://lldap.example.com |
| Authelia | https://auth.example.com |
| Jellyfin | https://jellyfin.example.com |
| Grafana | https://grafana.example.com |
| Miniflux | https://miniflux.example.com |
| Kavita | https://kavita.example.com |
| Audiobookshelf | https://audiobookshelf.example.com |
| Deluge | https://deluge.example.com |

### Default Credentials
| Service | Username | Password Location |
|---------|----------|-------------------|
| LLDAP Admin | `admin` | `secrets/lldap.yaml` (key: `user_pass`) |
| LLDAP Users | Your username | Set during user creation |

### Service Commands
```bash
# Restart Authelia
sudo systemctl restart authelia-main.service

# Restart LLDAP
sudo systemctl restart lldap.service

# View logs
journalctl -u authelia-main.service -f
journalctl -u lldap.service -f

# Check configuration
sudo authelia validate-config /etc/authelia/config.yml
```

### LDAP Structure
```
dc=labhome,dc=work
├── ou=people
│   ├── uid=admin
│   ├── uid=zeev
│   └── uid=...
└── ou=groups
    ├── cn=admin
    ├── cn=users
    └── cn=...
```

---

## Support & Documentation

### Official Documentation
- **Authelia**: https://www.authelia.com/
- **LLDAP**: https://github.com/lldap/lldap
- **OIDC Spec**: https://openid.net/connect/

### NixOS Configuration Files
- Authelia: `nix-config/modules/security/authelia/default.nix`
- LLDAP: `nix-config/modules/security/lldap/default.nix`
- Traefik: `nix-config/modules/networking/traefik/default.nix`
- Redis: `nix-config/modules/database/redis/default.nix`
- PostgreSQL: `nix-config/modules/database/postgresql/default.nix`

### Logs Location
- Authelia: `journalctl -u authelia-main.service`
- LLDAP: `journalctl -u lldap.service`
- Traefik: `journalctl -u traefik.service`
- Redis: `journalctl -u redis-homeserver.service`
- PostgreSQL: `journalctl -u postgresql.service`

---

**Last Updated**: 2025-12-31
**NixOS Configuration Version**: Latest from nix-config repository
