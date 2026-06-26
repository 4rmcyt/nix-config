# k3s Deployment Summary

## What Was Implemented

### 1. ✅ k3s Service Configuration
- **File**: [default.nix](default.nix)
- Lightweight Kubernetes as systemd service (not a VM!)
- Uses system PostgreSQL at `192.168.1.165:5432`
- Integrated with system-wide variables (`config.my.defaults`)
- No port conflicts with existing services
- Single-node setup optimized for homelab

### 2. ✅ Keycloak Deployment (via GitOps)
- Managed in separate repository: **https://github.com/4rmcyt/gitops.git**
- Directory: `k3s/keycloak/`
- Connects to system PostgreSQL
- Exposed via LoadBalancer on port 9000
- Accessible at `https://auth.example.com` via Cloudflare tunnel
- Auto-configured with sops secrets

### 3. ✅ Secrets Management
- **Database password**: From system sops (`keycloak_db_password` in postgresql.yaml)
- **Admin password**: From k3s sops (`k3s_keycloak_admin_password` in k3s.yaml)
- **Token file**: From k3s sops (`k3s_token_file` in k3s.yaml)
- Automatically synced to Kubernetes secrets via `k3s-setup-secrets` service
- No secrets in git repositories

### 4. ✅ GitOps Auto-Deployment
- **Repository**: https://github.com/4rmcyt/gitops.git
- **Path**: `k3s/` directory
- **Sync interval**: Every 5 minutes
- **Structure**: `k3s/<app-name>/deployment.yaml`, `service.yaml`, etc.
- Automatically applies changes from git
- No manual `kubectl apply` needed
- Timer-based sync service

### 5. ✅ Comprehensive Documentation
- **[README.md](README.md)** - How k3s works (explains it's NOT a VM!)
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Step-by-step deployment guide
- **[GITOPS-SETUP.md](GITOPS-SETUP.md)** - GitOps repository setup
- **[SUMMARY.md](SUMMARY.md)** - This file (complete overview)
- **[k3s-oidc-setup.md](../../security/keycloak/k3s-oidc-setup.md)** - OIDC configuration guide
- **[service-oidc-examples.nix](../../security/keycloak/service-oidc-examples.nix)** - Service integration examples

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                   NixOS Homeserver                            │
│                   (192.168.1.165)                             │
│                                                               │
│  System Services (systemd):                                  │
│  ├─ PostgreSQL :5432 ─────────────────┐                     │
│  ├─ Nginx                              │                     │
│  ├─ Miniflux :8086                     │                     │
│  ├─ Kavita :5000                       │                     │
│  ├─ Homepage :8082                     │                     │
│  └─ Other services                     │                     │
│                                         │                     │
│  k3s (systemd service):                │                     │
│  ├─ API Server :6443                   │                     │
│  ├─ Scheduler                          │                     │
│  ├─ Controller Manager                 │                     │
│  ├─ Kubelet :10250                     │                     │
│  ├─ Flannel (VXLAN) :8472 UDP          │                     │
│  │                                      │                     │
│  └─ containerd (containers):           │                     │
│      └─ Keycloak Pod ◄──────────────────┘                    │
│          └─ LoadBalancer :9000 → :8080                       │
│                                                               │
│  GitOps Sync (systemd timer: every 5m):                      │
│  ├─ Clone: https://github.com/4rmcyt/gitops.git              │
│  ├─ Watch: k3s/ directory                                    │
│  ├─ Detect: git commit changes                               │
│  └─ Apply: kubectl apply -f k3s/ --recursive                 │
│                                                               │
└──────────────────────────────────────────────────────────────┘
                           │
                           │ Port 9000
                           ▼
                  Cloudflare Tunnel
                    (cloudflared)
                           │
                           │ HTTPS
                           ▼
                https://auth.example.com
```

## How It Works

### k3s as a System Service

k3s runs as a **native Linux systemd service** on your NixOS system:
- ✅ **NOT a VM** - runs directly on host operating system
- ✅ **NOT Docker** - uses containerd as container runtime
- ✅ **Single binary** - all Kubernetes components included
- ✅ **Lightweight** - ~500MB memory footprint
- ✅ **Production-ready** - full Kubernetes API compatibility

Containers run **directly on your NixOS system** using:
- **containerd**: Container runtime
- **Linux namespaces**: Process isolation
- **cgroups**: Resource limits
- **Same kernel**: Shared with host OS

### GitOps Workflow

```
Developer
    │
    │ 1. Edit manifests
    │
    ▼
Local Machine (~/gitops/)
    │
    │ 2. git commit & push
    │
    ▼
GitHub (github.com/4rmcyt/gitops)
    │
    │ 3. Timer triggers (every 5min)
    │
    ▼
Homeserver (/var/lib/k3s-gitops)
    │
    │ 4. git fetch & compare
    │
    ├─ No changes? → Skip
    │
    └─ Changes detected?
        │
        │ 5. kubectl apply -f k3s/
        │
        ▼
    k3s Cluster
        │
        │ 6. Rolling update
        │
        ▼
    Updated Pods Running
```

## Configuration Files

### Main Configuration
**[modules/services/k3s/default.nix](default.nix)**
- k3s systemd service setup
- GitOps sync service and timer
- Kubernetes secrets sync from sops
- Firewall rules
- System directories

Key sections:
```nix
{
  # GitOps configuration
  gitOpsEnabled = true;
  gitOpsRepo = "https://github.com/4rmcyt/gitops.git";
  gitOpsBranch = "main";
  gitOpsPath = "k3s";
  gitOpsSyncInterval = "5m";

  # Services
  systemd.services.k3s = { ... };
  systemd.services.k3s-setup-secrets = { ... };
  systemd.services.k3s-gitops-sync = { ... };
  systemd.timers.k3s-gitops-sync = { ... };
}
```

### GitOps Repository Structure
**Repository**: https://github.com/4rmcyt/gitops

```
gitops/
├── README.md
└── k3s/
    ├── keycloak/
    │   ├── deployment.yaml      # Keycloak deployment
    │   ├── service.yaml          # LoadBalancer service
    │   └── README.md             # App documentation
    └── (future apps)/
        ├── app1/
        └── app2/
```

### Secrets (sops-encrypted)
**secrets/k3s.yaml**:
```yaml
tokenFile: <random-token>
keycloak_admin_password: <strong-password>
```

**secrets/postgresql.yaml** (already exists):
```yaml
keycloak_db_password: <db-password>
```

## Deployment Steps (Quick Reference)

1. **Create secrets** (`secrets/k3s.yaml`)
2. **Create GitOps repo** (https://github.com/4rmcyt/gitops)
3. **Add Keycloak manifests** (`k3s/keycloak/*.yaml`)
4. **Enable k3s module** in NixOS config
5. **Deploy**: `sudo nixos-rebuild switch`
6. **Verify**: `kubectl get all`
7. **Access**: https://auth.example.com

Full guide: [DEPLOYMENT.md](DEPLOYMENT.md)

## Port Analysis

**No conflicts detected!**

### k3s Ports
- **6443**: Kubernetes API server
- **8472**: Flannel VXLAN (UDP)
- **9000**: Keycloak LoadBalancer (shared with system keycloak config)
- **10250**: Kubelet metrics
- **30000-32767**: NodePort range (isolated from other services)

### Existing Service Ports
All existing services operate on different ports:
- **587**: SMTP (msmtp)
- **1883**: MQTT (Home Assistant)
- **3001**: Uptime Kuma
- **3003**: Grafana
- **3493**: NUT (Network UPS Tools)
- **5000**: Kavita
- **5232**: Radicale
- **5432**: PostgreSQL
- **6767**: Bazarr
- **7878**: Radarr
- **8069**: Microbin
- **8082**: Homepage Dashboard
- **8086**: Miniflux
- **8096**: Jellyfin
- **8123**: Home Assistant
- **8686**: Lidarr
- **8787**: Readarr
- **8881**: Atuin
- **8888**: Paperless
- **8989**: Sonarr
- **9292**: Audiobookshelf
- **9696**: Prowlarr
- **11434**: Ollama

## Services to Integrate with Keycloak OIDC

Once Keycloak is deployed and configured:

### Native OIDC Support
- ✅ **Miniflux** - Update config with OIDC settings
- ✅ **Kavita** - Configure via web UI

### Via oauth2-proxy
- ✅ **Homepage** - Protect with oauth2-proxy
- ✅ **Atuin** - Protect with oauth2-proxy
- ✅ **Microbin** - Protect with oauth2-proxy
- ✅ **Nixarr** (Sonarr, Radarr, Prowlarr, Lidarr, Readarr, Bazarr) - Protect with oauth2-proxy

Configuration guide: [k3s-oidc-setup.md](../../security/keycloak/k3s-oidc-setup.md)
Integration examples: [service-oidc-examples.nix](../../security/keycloak/service-oidc-examples.nix)

## Management Commands

### k3s Service
```bash
systemctl status k3s
systemctl restart k3s
journalctl -u k3s -f
```

### GitOps Sync
```bash
# View status
systemctl status k3s-gitops-sync
systemctl list-timers k3s-gitops-sync

# Manual trigger
sudo systemctl start k3s-gitops-sync

# Watch logs
journalctl -u k3s-gitops-sync -f

# Check repository
cd /var/lib/k3s-gitops
git status
git log -3
```

### Kubernetes Resources
```bash
# View all resources
kubectl get all

# Specific resources
kubectl get pods
kubectl get svc
kubectl get deployments
kubectl get secrets

# Logs
kubectl logs deployment/keycloak -f

# Describe
kubectl describe pod keycloak-xxxxx
kubectl describe svc keycloak

# Execute
kubectl exec -it deployment/keycloak -- bash

# Scale
kubectl scale deployment keycloak --replicas=2
```

## GitOps Development Workflow

### Adding a New Application

1. **Create directory** in gitops repo:
   ```bash
   cd ~/gitops
   mkdir -p k3s/my-app
   ```

2. **Create manifests**:
   ```bash
   # deployment.yaml, service.yaml, etc.
   ```

3. **Commit and push**:
   ```bash
   git add k3s/my-app/
   git commit -m "Add my-app deployment"
   git push
   ```

4. **Auto-deployed** within 5 minutes!

### Updating an Application

1. **Edit manifest**:
   ```bash
   vim k3s/keycloak/deployment.yaml
   # Change image version, replicas, etc.
   ```

2. **Commit and push**:
   ```bash
   git commit -am "Update Keycloak to 27.0"
   git push
   ```

3. **Rolling update** happens automatically!

### Rolling Back

```bash
git revert HEAD
git push
# Or
git reset --hard HEAD~1
git push --force
```

## Benefits of This Setup

### 1. Separation of Concerns
- **Critical services** (PostgreSQL, Nginx) run as system services
- **Applications** run in k3s containers
- Easy to isolate, update, and manage independently

### 2. GitOps Workflow
- **Infrastructure as Code** - all manifests version controlled
- **Automatic deployments** - push to git, auto-deployed
- **Audit trail** - git history shows all changes
- **Easy rollbacks** - revert git commit

### 3. Production Features
- **Health checks** - readiness and liveness probes
- **Resource limits** - prevent resource exhaustion
- **Automatic restarts** - self-healing
- **Rolling updates** - zero-downtime deployments
- **Load balancing** - klipper-lb for services

### 4. Centralized Authentication
- **Single Sign-On** via Keycloak
- **OAuth2/OIDC** for all services
- **Unified user management**
- **2FA support**

### 5. Future-Proof
- **Industry standard** - Kubernetes skills are transferable
- **Easy to scale** - add more apps via GitOps
- **Well documented** - extensive Kubernetes ecosystem
- **Migration path** - can move to multi-node cluster later

## Troubleshooting Quick Reference

| Issue | Command |
|-------|---------|
| k3s not starting | `journalctl -u k3s -n 50` |
| GitOps not syncing | `journalctl -u k3s-gitops-sync -f` |
| Pod not running | `kubectl describe pod <name>` |
| Check logs | `kubectl logs deployment/<name> -f` |
| Service not accessible | `kubectl get svc` |
| Secrets missing | `kubectl get secrets` |
| Database connection | `kubectl exec -it deployment/keycloak -- env \| grep KC_DB` |
| Manual sync | `sudo systemctl start k3s-gitops-sync` |

## Next Steps

1. ✅ **Deploy**: Follow [DEPLOYMENT.md](DEPLOYMENT.md)
2. ✅ **Setup GitOps**: Follow [GITOPS-SETUP.md](GITOPS-SETUP.md)
3. ✅ **Configure Keycloak**: Create realm and clients
4. ✅ **Integrate services**: Use [service-oidc-examples.nix](../../security/keycloak/service-oidc-examples.nix)
5. ✅ **Add more apps**: Deploy via GitOps
6. ✅ **Setup monitoring**: Prometheus/Grafana in k3s
7. ✅ **Configure backups**: PostgreSQL database backups

## Resources

### Documentation
- [README.md](README.md) - How k3s works
- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment guide
- [GITOPS-SETUP.md](GITOPS-SETUP.md) - GitOps setup
- [k3s-oidc-setup.md](../../security/keycloak/k3s-oidc-setup.md) - OIDC configuration

### External
- [k3s Documentation](https://docs.k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [GitOps Guide](https://www.gitops.tech/)

## Summary

You now have a **production-ready k3s setup** with:

✅ **k3s as systemd service** (not a VM!)
✅ **System PostgreSQL integration**
✅ **GitOps auto-deployment** from https://github.com/4rmcyt/gitops.git
✅ **Keycloak for SSO** at https://auth.example.com
✅ **Sops secrets management**
✅ **No port conflicts**
✅ **Comprehensive documentation**
✅ **Timer-based sync** every 5 minutes

**Repository Structure**:
- **NixOS Config**: k3s service configuration
- **GitOps Repo**: Kubernetes manifests (`k3s/<app>/`)
- **Secrets**: Encrypted with sops (never in git)

**Workflow**:
1. Edit manifests in gitops repo
2. Commit and push to GitHub
3. Auto-deployed within 5 minutes
4. Monitor with `kubectl get all`

Ready to deploy! 🚀
