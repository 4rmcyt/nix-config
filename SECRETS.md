# **Secrets Configuration Guide**

This document explains all secrets used in the NixOS configuration, their formats, required permissions, and how to obtain them.

## **🔐 Secret Management Overview**

All secrets are managed using **SOPS-nix** with **Age encryption**. The secrets are stored in `secrets.yaml` and automatically decrypted at runtime.

### **Age Encryption Setup (CRITICAL - DO THIS FIRST!)**

**Age** is a modern encryption tool used by SOPS to encrypt your secrets. You need to generate Age keys before you can use any secrets.

#### **1. Generate Age Key Pair**
```bash
# Install age tool
nix-shell -p age

# Generate new key pair
age-keygen -o ~/.config/sops/age/keys.txt

# This will output something like:
# Public key: age1yyy6r96rw9wt6xz7d6y0y8fzwd6l8h8zv8l0rw5xl2kwhltwzthcqtq8j6
# Private key saved to: ~/.config/sops/age/keys.txt
```

#### **2. Update .sops.yaml with Your Public Key**
```yaml
keys:
  - &admin_key age1YOUR_ACTUAL_PUBLIC_KEY_HERE  # Replace with output from age-keygen
```

#### **3. Initial Secrets Setup**
```bash
# Encrypt secrets.yaml with your key
sops -e -i secrets.yaml

# Edit secrets (will decrypt, open editor, re-encrypt on save)
sops secrets.yaml
```

### **SOPS Setup Requirements**
1. Age private key at: `~/.config/sops/age/keys.txt` (generated above)
2. Age public key in `.sops.yaml` (from age-keygen output)
3. Secrets encrypted with: `sops -e -i secrets.yaml`

---

## **👤 User Authentication**

### **`zeev_password`**
```yaml
zeev_password: "$y$j9T$jEo/iEqN827Jzqa0dtndo1$xoCk/8WqZ/v.JaCV0gj1Tr9Km/dVB9qKfKGn9/hjmk2"
```
- **Format**: yescrypt hashed password
- **Usage**: System user login password
- **Generation**: `mkpasswd -m yescrypt "your-password"`
- **Security**: This is already hashed, safe to store

---

## **☁️ Cloudflare Configuration**

### **`cloudflare_email`**
```yaml
cloudflare_email: "4rmcyt@gmail.com"
```
- **Format**: Email address (plaintext)
- **Usage**: Cloudflare account email for API authentication
- **Requirements**: Must be the email associated with your Cloudflare account
- **Permissions**: Account-level access for DNS management

### **`cloudflare_api_token`**
```yaml
cloudflare_api_token: "your-cloudflare-api-token"
```
- **Format**: 40-character alphanumeric string
- **Example**: `abc123def456ghi789jkl012mno345pqr678stu`
- **Usage**: Fail2ban Cloudflare integration for IP blocking
- **Required Permissions**:
  ```
  Zone:Zone:Read
  Zone:Zone Settings:Edit
  Zone:DNS:Edit
  Account:Account Filter Lists:Edit
  ```
- **How to Create**:
  1. Go to Cloudflare Dashboard → My Profile → API Tokens
  2. Create Token → Custom Token
  3. Set permissions above
  4. Add Zone Resources: Include → Specific zone → `labhome.work`

### **`cloudflare_tunnel_token`**
```yaml
cloudflare_tunnel_token: "your-tunnel-token"
```
- **Format**: Long base64-encoded string (200+ characters)
- **Example**: `eyJhIjoiYWJjZGVmZ2hpams...` (much longer)
- **Usage**: Cloudflare Tunnel daemon authentication
- **How to Obtain**:
  ```bash
  # Method 1: Via cloudflared CLI
  cloudflared tunnel login
  cloudflared tunnel create homeserver
  cloudflared tunnel token homeserver
  
  # Method 2: Via Cloudflare Dashboard
  # Zero Trust → Networks → Tunnels → Create → Copy token
  ```
- **Security**: Contains tunnel credentials, keep secure

### **`cloudflare_tunnel_credentials`**
```yaml
cloudflare_tunnel_credentials: |
  {
    "AccountTag": "your-account-tag",
    "TunnelSecret": "your-tunnel-secret", 
    "TunnelID": "your-tunnel-id"
  }
```
- **Format**: JSON object with specific fields
- **Field Details**:
  - `AccountTag`: 32-character hex string (Cloudflare account ID)
  - `TunnelSecret`: 44-character base64 string
  - `TunnelID`: UUID format (36 characters with hyphens)
- **Example**:
  ```json
  {
    "AccountTag": "a1b2c3d4e5f6789012345678901234567",
    "TunnelSecret": "abcdefghijklmnopqrstuvwxyz0123456789ABCDEF==",
    "TunnelID": "12345678-1234-5678-9abc-123456789012"
  }
  ```
- **How to Obtain**:
  ```bash
  # After creating tunnel
  cloudflared tunnel create homeserver
  # Credentials saved to: ~/.cloudflared/<tunnel-id>.json
  cat ~/.cloudflared/<tunnel-id>.json
  ```
- **Usage**: Tunnel authentication and configuration

---

## **🗄️ Database Passwords**

### **Application Database Passwords**
```yaml
keycloak_db_password: "a-very-strong-password-for-keycloak-db"
nextcloud_admin_password: "a-very-strong-password-for-nextcloud"
paperless_admin_password: "a-very-strong-password-for-paperless"
miniflux_admin_password: "a-very-strong-password-for-miniflux"
microbin_admin_password: "a-very-strong-password-for-microbin"
```
- **Format**: Strong plaintext passwords
- **Requirements**: 
  - Minimum 20 characters
  - Mix of letters, numbers, symbols
  - Unique for each service
- **Usage**: Service-specific admin accounts and database authentication
- **Generation**: `openssl rand -base64 32`

---

## **🔑 Authentication Services**

### **`radicale_htpasswd`**
```yaml
radicale_htpasswd: "zeev:$2y$05$..."
```
- **Format**: Apache htpasswd format
- **Structure**: `username:bcrypt_hash`
- **Generation**: 
  ```bash
  htpasswd -nbB zeev "your-password"
  # or
  python3 -c "import bcrypt; print('zeev:' + bcrypt.hashpw(b'your-password', bcrypt.gensalt()).decode())"
  ```
- **Usage**: Radicale CalDAV/CardDAV authentication

---

## **🌐 VPN Configuration**

### **`tailscale_auth_key`**
```yaml
tailscale_auth_key: "tskey-api-kwKrm4vGbY11CNTRL-dGzuq4oQJuE2H4Mht3mftEjHKi27bvaw"
```
- **Format**: Starts with `tskey-api-` or `tskey-auth-`
- **Length**: ~60 characters
- **Usage**: Automatic device enrollment in Tailscale network
- **How to Obtain**:
  1. Go to Tailscale Admin Console
  2. Settings → Keys
  3. Generate auth key
  4. Set options: Reusable, Ephemeral (optional)
- **Security**: Can be reused for multiple devices if configured

### **`wireguard_deluge`**
```yaml
wireguard_deluge: |
  [Interface]
  Address = 10.22.181.205
  PrivateKey = 0Gjr5IAytJOf+tzpFCqEOaiFTLAM2WY+d3cCuy7clGQ=
  DNS = 10.0.0.243,10.0.0.242

  [Peer]
  PublicKey = lrpyYc0R8FFpJKUvZ24WMqTyOgtUbAQNQyHb+IM4RhM=
  Endpoint = 149.50.218.23:1337
  AllowedIPs = 0.0.0.0/0
  PersistentKeepalive = 25
```
- **Format**: WireGuard configuration file format
- **Sections**:
  - `[Interface]`: Client configuration
    - `Address`: VPN IP assigned to your client
    - `PrivateKey`: Your WireGuard private key (44 chars base64)
    - `DNS`: DNS servers to use through VPN
  - `[Peer]`: VPN server configuration
    - `PublicKey`: Server's public key
    - `Endpoint`: Server IP:port
    - `AllowedIPs`: Traffic to route through VPN
    - `PersistentKeepalive`: Keep connection alive (seconds)
- **Usage**: Isolates Deluge traffic through PIA VPN
- **Source**: Downloaded from PIA control panel

---

## **📱 Notification Services**

### **Telegram Bot Configuration**
```yaml
telegram_bot_token: "your-telegram-bot-token"
telegram_chat_id: "your-telegram-chat-id"
```

#### **`telegram_bot_token`**
- **Format**: `<bot_id>:<auth_token>`
- **Example**: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`
- **How to Obtain**:
  1. Message `@BotFather` on Telegram
  2. Send `/newbot`
  3. Follow setup instructions
  4. Copy the token provided

#### **`telegram_chat_id`**
- **Format**: Numeric string (can be negative for groups)
- **Examples**: 
  - Personal chat: `123456789`
  - Group chat: `-987654321`
- **How to Obtain**:
  ```bash
  # Method 1: Send message to bot, then:
  curl https://api.telegram.org/bot<BOT_TOKEN>/getUpdates
  
  # Method 2: Forward message to @userinfobot
  # Method 3: Add @raw_data_bot to group
  ```

---

## **🔐 YubiKey/WebAuthn (Optional)**

### **YubiCloud Integration**
```yaml
yubikey_client_id: "your-yubico-client-id"
yubikey_secret_key: "your-yubico-secret-key"
```
- **Format**: 
  - `client_id`: Numeric string (5-6 digits)
  - `secret_key`: 28-character base64 string
- **Usage**: YubiCloud OTP validation (optional)
- **How to Obtain**:
  1. Go to https://upgrade.yubico.com/getapikey/
  2. Enter email and YubiKey OTP
  3. Receive Client ID and Secret Key

### **WebAuthn Configuration**
```yaml
webauthn_relying_party_name: "LabHome Services"
webauthn_relying_party_id: "labhome.work"
```
- **Format**: Human-readable strings
- **Usage**: WebAuthn/FIDO2 configuration in Keycloak
- **Requirements**:
  - `name`: Display name for your service
  - `id`: Must match your domain (without subdomain)

---

## **🔧 Secret Generation Commands**

### **Generate Strong Passwords**
```bash
# Method 1: OpenSSL
openssl rand -base64 32

# Method 2: urandom
head -c 32 /dev/urandom | base64

# Method 3: pwgen
pwgen -s 32 1

# Method 4: 1Password/Bitwarden
# Use password manager with 32+ character length
```

### **Hash Passwords**
```bash
# System password (yescrypt)
mkpasswd -m yescrypt "your-password"

# Radicale htpasswd (bcrypt)
htpasswd -nbB username "password"

# Manual bcrypt (Python)
python3 -c "import bcrypt; print(bcrypt.hashpw(b'password', bcrypt.gensalt()).decode())"
```

---

## **🛡️ Security Best Practices**

### **Secret Rotation Schedule**
- **Monthly**: Database passwords
- **Quarterly**: API tokens
- **Annually**: Tunnel credentials
- **As needed**: Compromised secrets

### **Access Control**
- Store Age private key securely
- Backup encryption keys separately
- Use unique passwords for each service
- Enable 2FA on all external accounts

### **Validation**
```bash
# Test secret decryption
sops -d secrets.yaml

# Verify secret access
sudo ls -la /run/secrets/

# Check service secret usage
journalctl -u keycloak | grep -i password
```

---

## **📋 Secret Checklist**

Before deploying, ensure you have:

- [ ] Generated Age encryption key
- [ ] Created all required Cloudflare tokens with correct permissions
- [ ] Set up Tailscale auth key
- [ ] Obtained PIA WireGuard configuration
- [ ] Created Telegram bot and obtained tokens
- [ ] Generated strong unique passwords for all services
- [ ] Created proper htpasswd entries
- [ ] Backed up all secrets securely
- [ ] Tested secret decryption with SOPS

---

## **🚨 Emergency Procedures**

### **Compromised Secrets**
1. Immediately rotate affected secrets
2. Revoke API tokens in respective services
3. Update `secrets.yaml` with new values
4. Rebuild system: `sudo nixos-rebuild switch --flake /etc/nixos`

### **Lost Encryption Key**
1. Regenerate Age key pair
2. Update `.sops.yaml` with new public key
3. Re-encrypt all secrets: `sops updatekeys secrets.yaml`
4. Deploy updated configuration

### **Secret Recovery**
- Age private key backup location: `~/.config/sops/age/keys.txt`
- Encrypted secrets backup: Git repository
- Service-specific recovery via admin panels
