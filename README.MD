# **LabHome NixOS Server Configuration**

A comprehensive NixOS configuration for a home server with multiple self-hosted services, VPN integration, and modern security features including YubiKey authentication.

## **🏗️ Architecture Overview**

### **Core Technologies**
- **Operating System**: NixOS (Declarative Linux Distribution)
- **Reverse Proxy**: Caddy (Local) + Cloudflare Tunnel (External)
- **DNS**: NextDNS (2bffa2.dns.nextdns.io) with DNS-over-TLS
- **VPN**: Tailscale (Mesh networking) + PIA WireGuard (Deluge isolation)
- **Secrets Management**: SOPS-nix with Age encryption
- **User Environment**: Home Manager with ZSH + NvChad
- **Authentication**: Keycloak with YubiKey/WebAuthn support

### **Service Architecture**

```mermaid
graph TB
    Internet --> CF[Cloudflare Tunnel]
    LAN[Local Network] --> Caddy
    
    CF --> Nextcloud
    CF --> Keycloak
    CF --> Microbin
    CF --> Miniflux
    CF --> Radicale
    CF --> Jellyfin
    
    Caddy --> Paperless
    Caddy --> Audiobookshelf
    Caddy --> HomeAssistant
    
    VPN[WireGuard VPN] --> Deluge
    Tailscale --> All[All Services]
```

## **🌐 Hosted Services**

### **External Access (via Cloudflare Tunnel)**
| Service | URL | Port | Description |
|---------|-----|------|-------------|
| **Nextcloud** | `nextcloud.labhome.work` | 8081 | File sync & collaboration platform |
| **Keycloak** | `keycloak.labhome.work` | 8080 | Identity & access management with YubiKey |
| **Microbin** | `paste.labhome.work` | 8083 | Private pastebin service |
| **Miniflux** | `rss.labhome.work` | 8084 | Minimalist RSS feed reader |
| **Radicale** | `cal.labhome.work` | 5232 | CalDAV/CardDAV server |
| **Jellyfin** | `jellyfin.labhome.work` | 8096 | Media streaming with GPU acceleration |

### **Local Network Only (via Caddy)**
| Service | URL | Port | Description |
|---------|-----|------|-------------|
| **Paperless-ngx** | `paperless.labhome.work` | 8082 | Document management system |
| **Audiobookshelf** | `audiobookshelf.labhome.work` | 8085 | Audiobook & podcast server |
| **Home Assistant** | `homeassistant.labhome.work` | 8123 | Home automation platform |

### **Background Services**
| Service | Port | Access | Description |
|---------|------|--------|-------------|
| **Deluge** | 8112 | VPN-isolated | BitTorrent client with PIA VPN |
| **PostgreSQL** | 5432 | Internal | Database for multiple services |
| **SSH** | 22 | Key-based auth | Remote administration |
| **Fail2ban** | - | Background | Intrusion prevention system |
| **Tailscale** | - | VPN mesh | Secure remote access |

## **🔧 Hardware Requirements**

### **Minimum Specifications**
- **CPU**: Intel i5-6500 or newer (Intel GPU required for Jellyfin acceleration)
- **RAM**: 8GB minimum (16GB+ recommended for multiple services)
- **Storage**: 
  - 100GB+ SSD for system
  - Additional storage for media and user data
- **Network**: Gigabit Ethernet connection
- **USB**: Port for YubiKey authentication

### **Hardware Features Enabled**
- ✅ Intel GPU hardware acceleration (VA-API) for Jellyfin
- ✅ YubiKey/FIDO2 authentication support
- ✅ PC/SC smart card daemon for hardware tokens
- ✅ Hardware monitoring and thermal management

## **🚀 Quick Start Installation**

### **1. Prerequisites**
```bash
# Download NixOS minimal ISO
# Boot from USB and run:
sudo -i
```

### **2. Clone and Install**
```bash
# Clone the configuration
git clone <your-repo-url> /mnt/etc/nixos
cd /mnt/etc/nixos

# Install system
nixos-install --flake .#homeserver

# Reboot
reboot
```

### **3. Initial Setup**
```bash
# Setup SOPS age key (after first boot)
mkdir -p ~/.config/sops/age
# Add your age private key to ~/.config/sops/age/keys.txt

# Generate strong passwords for services
./generate-passwords.sh

# Configure secrets
sops secrets.yaml

# Rebuild with secrets
sudo nixos-rebuild switch --flake /etc/nixos
```

## **🔑 Password Generation Guide**

### **Quick Password Generation**

#### **For Database Services**
```bash
# Generate secure passwords for all database services
echo "keycloak_db_password: \"$(openssl rand -base64 32)\""
echo "nextcloud_admin_password: \"$(openssl rand -base64 32)\""
echo "paperless_admin_password: \"$(openssl rand -base64 32)\""
echo "miniflux_admin_password: \"$(openssl rand -base64 32)\""
echo "microbin_admin_password: \"$(openssl rand -base64 32)\""
```

#### **For System Authentication**
```bash
# Generate system user password hash
read -s -p "Enter password for user zeev: " PASSWORD
echo "zeev_password: \"$(echo $PASSWORD | mkpasswd -m yescrypt -s)\""

# Generate Radicale htpasswd entry
read -s -p "Enter password for Radicale: " RADPASS
echo "radicale_htpasswd: \"$(echo "zeev:$(echo $RADPASS | htpasswd -niB zeev | cut -d: -f2)\"")"
```

### **Password Generation Methods**

#### **Method 1: OpenSSL (Recommended)**
```bash
# 32-character base64 password
openssl rand -base64 32

# 40-character hex password  
openssl rand -hex 20

# Custom length (adjust number for different lengths)
openssl rand -base64 24  # ~32 chars
openssl rand -base64 48  # ~64 chars
```

#### **Method 2: System Random**
```bash
# Using /dev/urandom
head -c 32 /dev/urandom | base64

# Using /dev/random (slower, more entropy)
head -c 32 /dev/random | base64

# Remove special characters if needed
head -c 32 /dev/urandom | base64 | tr -d '/+='
```

#### **Method 3: pwgen Tool**
```bash
# Install pwgen first
nix-shell -p pwgen

# Generate passwords
pwgen -s 32 1          # Secure 32-char password
pwgen -s -y 32 1       # With symbols
pwgen -s -n 32 5       # 5 different passwords
```

#### **Method 4: Password Managers**
- **1Password**: Generate 32+ character passwords
- **Bitwarden**: Use password generator with symbols
- **KeePass**: Configure custom generation rules
- **LastPass**: Generate complex passwords

### **Batch Password Generation Script**

Create a helper script for generating all passwords:

```bash
#!/bin/bash
# save as generate-passwords.sh

echo "# Generated passwords for LabHome server"
echo "# $(date)"
echo ""

echo "# User authentication"
echo "zeev_password: \"# Run: mkpasswd -m yescrypt 'your-password'\""
echo "radicale_htpasswd: \"# Run: htpasswd -nbB zeev 'your-password'\""
echo ""

echo "# Database passwords"
services=("keycloak_db" "nextcloud_admin" "paperless_admin" "miniflux_admin" "microbin_admin")
for service in "${services[@]}"; do
    password=$(openssl rand -base64 32)
    echo "${service}_password: \"${password}\""
done

echo ""
echo "# API tokens (generate manually)"
echo "cloudflare_api_token: \"# Get from Cloudflare dashboard\""
echo "cloudflare_tunnel_token: \"# Run: cloudflared tunnel token homeserver\""
echo "tailscale_auth_key: \"# Get from Tailscale admin console\""
echo "telegram_bot_token: \"# Get from @BotFather\""
echo "telegram_chat_id: \"# Get from bot messages\""

echo ""
echo "# Copy these values to your secrets.yaml file"
```

Make it executable and run:
```bash
chmod +x generate-passwords.sh
./generate-passwords.sh > generated-passwords.txt
```

### **Password Security Guidelines**

#### **Strength Requirements**
- **Minimum Length**: 20 characters for admin, 32 for database
- **Character Types**: Uppercase, lowercase, numbers, symbols
- **Uniqueness**: Never reuse passwords across services
- **Randomness**: Use cryptographically secure generators

#### **Storage Best Practices**
- Store in encrypted password manager
- Backup encryption keys separately
- Use SOPS for configuration secrets
- Never store plaintext in version control

#### **Password Validation**
```bash
# Test password strength
echo "your-password" | zxcvbn

# Check password in Have I Been Pwned
curl -s "https://api.pwnedpasswords.com/range/$(echo -n 'password' | sha1sum | cut -c1-5)"

# Verify hash generation
echo "test" | mkpasswd -m yescrypt -s
```
## **🔐 Security & Authentication**

### **Multi-Factor Authentication**
- **YubiKey Support**: WebAuthn/FIDO2 integration with Keycloak
- **SSH Keys Only**: Password authentication disabled
- **Encrypted Secrets**: All sensitive data encrypted with SOPS
- **VPN Isolation**: Deluge runs in isolated WireGuard namespace

### **Network Security**
- **Cloudflare Protection**: DDoS mitigation and SSL termination
- **Fail2ban**: Automated intrusion detection and prevention
- **Firewall**: Minimal attack surface with NixOS firewall
- **DNS Security**: NextDNS with malware/tracker blocking

### **Access Control Matrix**
| Service | Local | Tailscale | Cloudflare | Auth Required |
|---------|-------|-----------|------------|---------------|
| Nextcloud | ❌ | ✅ | ✅ | Keycloak SSO |
| Keycloak | ❌ | ✅ | ✅ | YubiKey + Password |
| Jellyfin | ❌ | ✅ | ✅ | Local account |
| Home Assistant | ✅ | ✅ | ❌ | Local account |
| Paperless | ✅ | ✅ | ❌ | Local account |
| SSH | ✅ | ✅ | ❌ | Key-based only |

## **📁 Project Structure**

```
/etc/nixos/
├── 📄 flake.nix                    # Flake configuration and inputs
├── 📄 configuration.nix            # Main system configuration
├── 📄 disko.nix                   # Declarative disk partitioning
├── 📄 networking.nix              # Network and DNS configuration
├── 📄 home.nix                    # Home Manager user environment
├── 🔒 secrets.yaml                # SOPS encrypted secrets
├── 📁 services/                   # Service configurations
│   ├── 🌐 cloudflared.nix         # Cloudflare Tunnel
│   ├── 🌐 caddy.nix               # Local reverse proxy
│   ├── 📥 deluge-vpn.nix          # VPN-isolated torrenting
│   ├── 🛡️ fail2ban.nix            # Intrusion prevention
│   ├── 🏠 home-assistant.nix      # Home automation
│   ├── 🎬 jellyfin.nix            # Media streaming
│   ├── 🔑 keycloak.nix            # Identity management
│   ├── 🎵 media-content.nix       # Audiobookshelf, Miniflux, Microbin
│   ├── ☁️ nextcloud.nix           # File synchronization
│   ├── 📄 paperless.nix           # Document management
│   ├── 📅 radicale.nix            # Calendar/contacts
│   ├── 🔗 tailscale.nix           # VPN mesh networking
│   ├── 📱 tg-notify.nix           # Telegram notifications
│   └── 🔐 yubikey.nix             # Hardware authentication
└── 📁 scripts/                   # Management scripts
    └── keycloak-yubikey-setup.nix
```

## **🛠️ Management & Operations**

### **System Management**
```bash
# Update system
sudo nixos-rebuild switch --flake /etc/nixos

# Update flake inputs
nix flake update

# Check system status
systemctl status

# View system logs
journalctl -f
```

### **Service Management**
```bash
# Service status
systemctl status keycloak
systemctl status jellyfin
systemctl status tailscale

# Service logs
journalctl -u nextcloud -f
journalctl -u home-assistant -n 100

# Restart services
sudo systemctl restart caddy
sudo systemctl restart cloudflared
```

### **Secret Management**
```bash
# Edit encrypted secrets
sops secrets.yaml

# Reload secrets (automatic on rebuild)
sudo nixos-rebuild switch --flake /etc/nixos

# Check secret access
sudo ls -la /run/secrets/
```

### **Backup Strategy**
```bash
# Essential directories to backup:
/etc/nixos/                    # Configuration (this repo)
/home/zeev/                    # User data
/var/lib/postgresql/           # Databases
/var/lib/nextcloud/           # Nextcloud data
~/.config/sops/age/           # Encryption keys
```

## **🌐 Access Information**

### **Web Interfaces**
- **Nextcloud**: https://nextcloud.labhome.work
- **Keycloak**: https://keycloak.labhome.work
- **Jellyfin**: https://jellyfin.labhome.work
- **Home Assistant**: https://homeassistant.labhome.work
- **Paperless**: https://paperless.labhome.work
- **Audiobookshelf**: https://audiobookshelf.labhome.work

### **Mobile Apps**
- **Nextcloud**: iOS/Android apps available
- **Home Assistant**: Companion apps for iOS/Android
- **Jellyfin**: Mobile apps for media streaming
- **Tailscale**: Mobile VPN access

### **Desktop Integration**
- **Nextcloud**: Desktop sync clients
- **Radicale**: CalDAV/CardDAV in calendar/contact apps
- **SSH**: Terminal access with key authentication

## **🔧 Troubleshooting Guide**

### **Common Issues**

#### **Service Won't Start**
```bash
# Check service status and logs
systemctl status <service-name>
journalctl -u <service-name> -n 50

# Check dependencies
systemctl list-dependencies <service-name>
```

#### **DNS Resolution Issues**
```bash
# Check DNS configuration
resolvectl status
systemctl status systemd-resolved

# Test DNS resolution
nslookup google.com
dig @45.90.28.0 google.com
```

#### **Secret Access Problems**
```bash
# Verify secrets are accessible
sudo ls -la /run/secrets/
sudo cat /run/secrets/nextcloud_admin_password

# Restart SOPS if needed
sudo systemctl restart sops-nix
```

#### **YubiKey Not Working**
```bash
# Check USB device detection
lsusb | grep Yubico

# Restart PC/SC daemon
sudo systemctl restart pcscd

# Test YubiKey functionality
ykman info
```

#### **Network Connectivity**
```bash
# Check Tailscale status
sudo tailscale status

# Test Cloudflare tunnel
sudo cloudflared tunnel info homeserver

# Check local network services
curl -I http://localhost:8080  # Keycloak
curl -I http://localhost:8081  # Nextcloud
```

### **Emergency Access**
1. **Physical Console**: Direct server access
2. **SSH**: `ssh zeev@<server-ip>` (key-based)
3. **Tailscale**: VPN access even if main services are down
4. **Recovery Mode**: Boot into NixOS rescue mode

### **Performance Monitoring**
```bash
# System resources
htop
iotop
nethogs

# Service-specific logs
journalctl -u jellyfin -f     # Media transcoding
journalctl -u postgresql -f   # Database performance
journalctl -u caddy -f        # Web server access
```

## **🔄 Update & Maintenance**

### **Regular Maintenance Tasks**
- **Weekly**: Update flake inputs and rebuild system
- **Monthly**: Review fail2ban logs and security events
- **Quarterly**: Update Cloudflare tunnel configuration
- **As needed**: Rotate secrets and authentication keys

### **System Updates**
```bash
# Update flake inputs
nix flake update

# Rebuild system
sudo nixos-rebuild switch --flake /etc/nixos

# Check for issues
journalctl -b | grep -i error
systemctl --failed
```

## **🔑 Initial Configuration Steps**

### **1. Cloudflare Tunnel Setup**
```bash
# Login to Cloudflare
cloudflared login

# Create tunnel
cloudflared tunnel create homeserver

# Get tunnel credentials and add to secrets.yaml
```

### **2. Tailscale Configuration**
```bash
# Service starts automatically with auth key from secrets
# Check status
sudo tailscale status

# Enable key features
sudo tailscale set --accept-dns --accept-routes --ssh
```

### **3. YubiKey Setup**
```bash
# Run setup script
setup-keycloak-yubikey

# Follow Keycloak admin console instructions:
# 1. Enable WebAuthn authenticators
# 2. Configure authentication flows
# 3. Set up user security keys
```

### **4. Service-Specific Setup**

#### **Nextcloud**
- Access https://nextcloud.labhome.work
- Login with admin credentials from secrets
- Configure external storage, apps, and user accounts

#### **Home Assistant**
- Access https://homeassistant.labhome.work
- Complete initial setup wizard
- Configure integrations and automations

#### **Jellyfin**
- Access https://jellyfin.labhome.work
- Complete setup wizard
- Configure media libraries (/home/zeev/media)

## **📚 Documentation & Resources**

### **NixOS Resources**
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [SOPS-nix Documentation](https://github.com/Mic92/sops-nix)

### **Service Documentation**
- [Keycloak Admin Guide](https://www.keycloak.org/docs/latest/server_admin/)
- [Nextcloud Admin Manual](https://docs.nextcloud.com/server/latest/admin_manual/)
- [Jellyfin Documentation](https://jellyfin.org/docs/)
- [Home Assistant Docs](https://www.home-assistant.io/docs/)

### **Security Resources**
- [YubiKey Setup Guide](https://developers.yubico.com/WebAuthn/)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Tailscale Documentation](https://tailscale.com/kb/)

## **🤝 Contributing**

This configuration is designed for personal use but can be adapted for similar setups. Key areas for customization:

1. **Domain Names**: Update `labhome.work` to your domain
2. **User Accounts**: Modify user configurations in `configuration.nix`
3. **Service Selection**: Enable/disable services based on needs
4. **Hardware**: Adjust GPU and hardware-specific settings
5. **Secrets**: Generate your own encryption keys and secrets

## **⚠️ Security Considerations**

- **Change Default Passwords**: All default passwords in secrets.yaml must be changed
- **SSH Keys**: Upload your public SSH key before disabling password auth
- **Firewall**: Review and adjust firewall rules for your network
- **Backups**: Implement regular backups of critical data
- **Updates**: Keep system and services updated regularly

## **📄 License**

This configuration is provided under the MIT license for educational and personal use. Individual services maintain their respective licenses.

---

**🏠 Built with ❤️ for the home lab community**

*Last updated: July 2025*
