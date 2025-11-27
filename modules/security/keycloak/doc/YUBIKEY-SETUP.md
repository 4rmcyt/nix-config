# YubiKey Authentication Setup for Keycloak

This guide explains how to set up YubiKey (and other FIDO2/WebAuthn security keys) for two-factor authentication and passwordless login in Keycloak.

## Overview

Keycloak supports two WebAuthn/FIDO2 authentication modes:

1. **Two-Factor Authentication (2FA)**: Use YubiKey as a second factor after password
2. **Passwordless**: Use YubiKey as the only authentication method (no password needed)

Both modes are pre-configured in the realm and ready to use.

## Prerequisites

- YubiKey 5 series or any FIDO2-compatible security key
- Modern browser with WebAuthn support (Chrome, Firefox, Edge, Safari)
- HTTPS enabled (WebAuthn requires secure context)

## Configuration Details

### WebAuthn Policy Settings

The realm includes two WebAuthn policies configured in [realm.nix](realm.nix:38-60):

**Two-Factor Authentication (2FA) Policy:**
- **Relying Party**: `${domain}` (your homelab domain)
- **Algorithms**: ES256, RS256 (supports most security keys)
- **Attestation**: None (privacy-friendly, doesn't require vendor attestation)
- **Authenticator Type**: Cross-platform (external security keys like YubiKey)
- **Resident Key**: Not required (credentials stored on Keycloak server)
- **User Verification**: Preferred (uses PIN/biometric if available)
- **Timeout**: 60 seconds

**Passwordless Policy:**
- Same as 2FA, but with:
- **Resident Key**: Required (credentials stored on the security key itself)
- **User Verification**: Required (must use PIN or biometric)

### Supported Security Keys

- **YubiKey 5 Series** (5C, 5Ci, 5 NFC, 5C NFC, etc.)
- **YubiKey Security Key Series** (FIDO2)
- **YubiKey Bio Series** (FIDO2 + biometric)
- **Titan Security Key** (Google)
- **Feitian Keys** (FIDO2)
- **SoloKeys**
- Any FIDO2/WebAuthn certified authenticator

## Setup Guide

### 1. Enable WebAuthn for Users

There are two ways to enable WebAuthn authentication:

#### Option A: User Self-Registration (Recommended)

1. Log in to your Keycloak account at `https://auth.${domain}/realms/homelab/account`
2. Navigate to **Account Security** → **Signing In**
3. Under **Two-Factor Authentication**, click **Set up Security Key**
4. Follow the browser prompts:
   - Insert your YubiKey
   - Touch the YubiKey when prompted
   - Set a display name for your key (e.g., "YubiKey 5C")
5. Your YubiKey is now registered!

#### Option B: Admin-Required Registration

Admins can require users to register a security key on next login:

1. Log in to Keycloak admin console at `https://auth.${domain}`
2. Switch to the `homelab` realm
3. Navigate to **Users** → Select user → **Credentials** tab
4. Click **Required User Actions** dropdown
5. Select **WebAuthn Register** (for 2FA) or **WebAuthn Register Passwordless**
6. Click **Save**
7. User will be prompted to register their YubiKey on next login

### 2. Setting Up Two-Factor Authentication (2FA)

After registering your YubiKey as described above:

1. Log out from all sessions
2. Log in with username/email and password
3. You'll be prompted to insert and touch your YubiKey
4. Login completes after YubiKey verification

**Benefits:**
- Password + YubiKey = strong two-factor authentication
- Protects against phishing and password theft
- YubiKey can be used across multiple devices

### 3. Setting Up Passwordless Login

Passwordless requires a security key with resident credential support (YubiKey 5 series).

#### Register for Passwordless

1. Log in to `https://auth.${domain}/realms/homelab/account`
2. Navigate to **Account Security** → **Signing In**
3. Under **Passwordless**, click **Set up Security Key**
4. Insert your YubiKey and touch when prompted
5. **Important**: Enter your YubiKey PIN when requested
6. Set a display name (e.g., "YubiKey 5C - Passwordless")

#### Using Passwordless Login

1. Navigate to login page
2. Click **Try another way** → **Security Key**
3. Insert YubiKey and touch
4. Enter YubiKey PIN
5. Login completes without password!

**Benefits:**
- No password to remember or type
- Faster login
- Immune to phishing
- Works across devices (resident credentials stored on key)

**Limitations:**
- YubiKey 5 series supports ~25 resident credentials
- Requires YubiKey PIN (set via YubiKey Manager)
- Need backup key in case primary is lost

## Best Practices

### 1. Register Multiple Security Keys

Always register at least 2 security keys per account:

- **Primary**: Your daily-use YubiKey
- **Backup**: Stored securely at home/safe

To register additional keys:
1. Go to Account Security → Signing In
2. Click **Set up Security Key** again
3. Use your second YubiKey

### 2. Set a YubiKey PIN

For passwordless authentication, set a PIN on your YubiKey:

```bash
# Install YubiKey Manager
nix-shell -p yubikey-manager

# Set FIDO2 PIN
ykman fido access change-pin
```

Default PIN is usually not set. Choose a strong 6-8 digit PIN.

### 3. Label Your Keys

Use the display name field to identify your keys:
- "YubiKey 5C - Primary"
- "YubiKey 5 NFC - Backup"
- "YubiKey Bio - Laptop"

### 4. Test Backup Keys Regularly

Periodically test that your backup keys work to avoid lockouts.

### 5. Keep Recovery Options

Consider enabling one of these fallback methods:
- **TOTP (Authenticator App)**: Google Authenticator, Authy
- **Recovery Codes**: One-time use codes stored securely
- **Backup Email**: For password reset

## Troubleshooting

### YubiKey Not Detected

**Browser issues:**
- Ensure you're using HTTPS (WebAuthn requires secure context)
- Try a different browser (Chrome/Firefox recommended)
- Check browser permissions for USB devices

**YubiKey issues:**
- Ensure YubiKey is inserted properly
- Try a different USB port
- Update YubiKey firmware via YubiKey Manager
- Test YubiKey at [webauthn.io](https://webauthn.io)

### "User Verification" Error

This means your YubiKey doesn't support PIN/biometric, but the policy requires it.

**Solutions:**
1. Set a FIDO2 PIN on your YubiKey (recommended):
   ```bash
   ykman fido access change-pin
   ```
2. Or modify the realm policy to `"preferred"` instead of `"required"`

### Passwordless Registration Fails

**Check YubiKey model:**
- YubiKey 5 series supports resident credentials
- Older YubiKeys (FIDO U2F only) don't support passwordless

**Check resident credential slots:**
- YubiKey 5 series has ~25 slots
- List credentials: `ykman fido credentials list`
- Delete old credentials: `ykman fido credentials delete`

### Lost All Security Keys

If you lose access to all registered security keys:

1. **If you have password access**: Log in and register a new key
2. **If passwordless only**: Contact your admin for account recovery
3. **If you're the admin**: Use the admin console to:
   - Reset user credentials
   - Remove WebAuthn required action
   - Have user set new password

**Prevention**: Always register at least 2 security keys!

### Touch Not Responding

- Ensure you're touching the correct area (gold/silver contact point)
- Touch for 1-2 seconds (not a quick tap)
- Some YubiKeys require a firm press

### Firefox: "This security key is already registered"

Firefox sometimes shows this error incorrectly. Solutions:
- Try Chrome/Chromium
- Clear Firefox cache and cookies
- Use a different security key

## Advanced Configuration

### Limit to Specific YubiKey Models

To only allow specific YubiKey models, edit [realm.nix](realm.nix:48):

```nix
webAuthnPolicyAcceptableAaguids = [
  "cb69481e-8ff7-4039-93ec-0a2729a154a8"  # YubiKey 5 FIPS
  "ee882879-721c-4913-9775-3dfcce97072a"  # YubiKey 5
  "2fc0579f-8113-47ea-b116-bb5a8db9202a"  # YubiKey 5 NFC
];
```

Find AAGUIDs at: https://github.com/passkeydeveloper/passkey-authenticator-aaguids

### Require YubiKey for Specific Users

1. Admin Console → Users → Select User
2. Role Mappings → Assign custom role (e.g., "require-yubikey")
3. Create authentication flow that enforces WebAuthn for that role

### Customize WebAuthn Registration Flow

The default flow works for most cases, but you can customize:

1. Admin Console → Authentication → Flows
2. Duplicate "Browser" flow
3. Add/remove/configure WebAuthn steps
4. Bind to "Browser" or specific clients

### Monitor WebAuthn Usage

Check WebAuthn events in the admin console:

1. Realm Settings → Events → Login Events
2. Look for:
   - `UPDATE_TOTP` (TOTP setup)
   - `REMOVE_TOTP` (TOTP removal)
   - Custom WebAuthn events

## Security Considerations

### WebAuthn vs TOTP

| Feature | YubiKey (WebAuthn) | TOTP (Authenticator App) |
|---------|-------------------|-------------------------|
| Phishing Resistant | ✅ Yes | ❌ No |
| Device Binding | ✅ Yes | ❌ No (codes can be copied) |
| Ease of Use | ✅ Touch to login | ⚠️ Must type 6-digit code |
| Cost | ⚠️ $25-80 per key | ✅ Free |
| Backup | ⚠️ Need multiple keys | ✅ Easy to backup |

**Recommendation**: Use YubiKey for high-security accounts, TOTP as backup.

### Relying Party ID (RP ID)

The RP ID must match your domain. Our configuration uses:

```nix
webAuthnPolicyRpId = domain;  # e.g., example.com
```

**Important**: If you change domains, you'll need to re-register all YubiKeys.

### Attestation

We use `"none"` attestation for privacy (doesn't leak YubiKey serial number). If you need to verify specific YubiKey models are used, change to:

```nix
webAuthnPolicyAttestationConveyancePreference = "direct";
```

### Resident Keys

**Standard (non-resident) keys**:
- Credentials stored on Keycloak server
- YubiKey stores only cryptographic key
- Unlimited registrations possible

**Resident keys (passwordless)**:
- Credentials stored on YubiKey (~25 slots)
- Enables true passwordless (no username entry needed)
- Limited slots per key

## References

- [Keycloak WebAuthn Documentation](https://www.keycloak.org/docs/latest/server_admin/#_webauthn)
- [WebAuthn Specification](https://www.w3.org/TR/webauthn-2/)
- [YubiKey 5 Series](https://www.yubico.com/products/yubikey-5-overview/)
- [YubiKey Manager](https://www.yubico.com/support/download/yubikey-manager/)
- [FIDO Alliance](https://fidoalliance.org/)

## Example Setup Script

For automated YubiKey setup across multiple accounts:

```bash
#!/usr/bin/env bash
# Register YubiKey for a user via Keycloak API

KEYCLOAK_URL="https://auth.${domain}"
REALM="homelab"
USERNAME="your-username"
PASSWORD="your-password"

# Get access token
TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=$USERNAME" \
  -d "password=$PASSWORD" \
  -d "grant_type=password" \
  -d "client_id=account" | jq -r '.access_token')

# Get user ID
USER_ID=$(curl -s "$KEYCLOAK_URL/realms/$REALM/account" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.id')

echo "User ID: $USER_ID"
echo "Visit: $KEYCLOAK_URL/realms/$REALM/account/#/security/signingin"
echo "to register your YubiKey interactively"
```

This provides a starting point for automation, though registration itself requires user interaction (browser + YubiKey touch).
