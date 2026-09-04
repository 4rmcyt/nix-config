# k3s Module Documentation Index

Quick navigation to all k3s documentation.

## 📚 Documentation Files

### 🚀 [DEPLOYMENT.md](DEPLOYMENT.md)
**Start here for deployment!**
- Complete step-by-step deployment guide
- Prerequisites checklist
- Secrets setup
- GitOps repository creation
- Verification steps
- Troubleshooting

### 📖 [README.md](README.md)
**How k3s works**
- What is k3s? (Explains it's NOT a VM!)
- Architecture overview
- How it differs from Docker/Podman
- Resource usage
- Why use k3s vs systemd services

### 🔄 [GITOPS-SETUP.md](GITOPS-SETUP.md)
**GitOps repository setup**
- Creating https://github.com/4rmcyt/gitops
- Directory structure: `k3s/keycloak/`
- Adding Keycloak manifests
- Adding more applications
- GitOps workflow explained
- Best practices

### 📋 [SUMMARY.md](SUMMARY.md)
**Complete overview**
- What was implemented
- Architecture diagrams
- Configuration files reference
- Port analysis
- Management commands
- Quick troubleshooting table

## 🎯 Quick Start

1. **Understand k3s**: Read [README.md](README.md)
2. **Deploy**: Follow [DEPLOYMENT.md](DEPLOYMENT.md)
3. **Setup GitOps**: Follow [GITOPS-SETUP.md](GITOPS-SETUP.md)
4. **Reference**: Use [SUMMARY.md](SUMMARY.md) for commands and troubleshooting

## 🔐 Security & OIDC

### [../../security/keycloak/k3s-oidc-setup.md](../../security/keycloak/k3s-oidc-setup.md)
Complete guide for configuring Keycloak OIDC:
- Creating realms
- Configuring clients for services
- User management
- Testing

### [../../security/keycloak/service-oidc-examples.nix](../../security/keycloak/service-oidc-examples.nix)
Example configurations for:
- Miniflux (native OIDC)
- Kavita (native OIDC)
- Homepage (via oauth2-proxy)
- Atuin (via oauth2-proxy)
- Microbin (via oauth2-proxy)
- Nixarr services (via oauth2-proxy)

## 📁 File Structure

```
modules/services/k3s/
├── default.nix              # Main k3s configuration
├── INDEX.md                 # This file
├── README.md                # How k3s works
├── DEPLOYMENT.md            # Deployment guide
├── GITOPS-SETUP.md          # GitOps setup
└── SUMMARY.md               # Complete overview
```

## 🔗 Related Modules

- [../../database/postgresql](../../database/postgresql) - System PostgreSQL
- [../../networking/cloudflared](../../networking/cloudflared) - Cloudflare tunnel
- [../../security/keycloak](../../security/keycloak) - Keycloak OIDC
- [../../security/oauth2-proxy](../../security/oauth2-proxy) - OAuth2 proxy

## ⚡ Common Commands

```bash
# k3s service
systemctl status k3s
journalctl -u k3s -f

# GitOps sync
systemctl status k3s-gitops-sync
sudo systemctl start k3s-gitops-sync
journalctl -u k3s-gitops-sync -f

# Kubernetes
kubectl get all
kubectl get pods
kubectl logs deployment/keycloak -f
kubectl describe pod <name>

# Git repository
cd /var/lib/k3s-gitops
git status
git log -3
```

## 🎓 Learning Path

### Beginners
1. Read [README.md](README.md) - Understand what k3s is
2. Follow [DEPLOYMENT.md](DEPLOYMENT.md) - Step-by-step deployment
3. Use [SUMMARY.md](SUMMARY.md) - Reference for commands

### Intermediate
1. Read [GITOPS-SETUP.md](GITOPS-SETUP.md) - Understand GitOps workflow
2. Deploy additional applications
3. Configure OIDC for services

### Advanced
1. Customize k3s configuration in `default.nix`
2. Add monitoring (Prometheus/Grafana)
3. Setup automated backups
4. Optimize resource limits

## 🆘 Getting Help

### Troubleshooting
- See [DEPLOYMENT.md#troubleshooting](DEPLOYMENT.md#troubleshooting)
- Check [SUMMARY.md#troubleshooting-quick-reference](SUMMARY.md#troubleshooting-quick-reference)

### Common Issues
| Issue | Solution |
|-------|----------|
| k3s won't start | Check [DEPLOYMENT.md#k3s-not-starting](DEPLOYMENT.md#k3s-not-starting) |
| GitOps not syncing | Check [DEPLOYMENT.md#gitops-not-syncing](DEPLOYMENT.md#gitops-not-syncing) |
| Pod not running | Check [DEPLOYMENT.md#pods-not-running](DEPLOYMENT.md#pods-not-running) |
| Keycloak not accessible | Check [DEPLOYMENT.md#keycloak-not-accessible](DEPLOYMENT.md#keycloak-not-accessible) |

## 🔄 Workflow Overview

```
┌─────────────────────────────────────────────────┐
│ 1. Create secrets (secrets/k3s.yaml)            │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ 2. Create GitOps repo (github.com/4rmcyt/gitops)│
│    └─ Add manifests to k3s/keycloak/            │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ 3. Enable k3s module in NixOS config            │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ 4. Deploy: sudo nixos-rebuild switch            │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ 5. Verify: kubectl get all                      │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ 6. Access: https://auth.<domain>            │
└─────────────────────────────────────────────────┘
```

## 📊 Architecture Summary

```
NixOS Homeserver
├─ System Services (systemd)
│  ├─ PostgreSQL :5432
│  ├─ Nginx
│  └─ Other services
│
├─ k3s (systemd service)
│  ├─ API Server :6443
│  ├─ Flannel :8472 (UDP)
│  └─ containerd
│     └─ Keycloak Pod
│        └─ LoadBalancer :9000
│
└─ GitOps Sync (timer: 5min)
   └─ github.com/4rmcyt/gitops
      └─ k3s/keycloak/*.yaml
```

## 🎯 Key Features

✅ k3s as systemd service (not a VM!)
✅ System PostgreSQL integration
✅ GitOps auto-deployment
✅ Keycloak for SSO
✅ Sops secrets management
✅ No port conflicts
✅ Comprehensive documentation

## 📝 Next Steps

1. **First Time?** → [README.md](README.md)
2. **Ready to Deploy?** → [DEPLOYMENT.md](DEPLOYMENT.md)
3. **Need Reference?** → [SUMMARY.md](SUMMARY.md)
4. **Setup GitOps?** → [GITOPS-SETUP.md](GITOPS-SETUP.md)
5. **Configure OIDC?** → [k3s-oidc-setup.md](../../security/keycloak/k3s-oidc-setup.md)

Happy deploying! 🚀
