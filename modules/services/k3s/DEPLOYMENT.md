# K3s Deployment Guide

Complete guide for deploying k3s with Keycloak using GitOps workflow.

## Prerequisites

- ✅ NixOS system configured
- ✅ System PostgreSQL running ([modules/database/postgresql](../../database/postgresql))
- ✅ Cloudflare tunnel configured ([modules/networking/cloudflared](../../networking/cloudflared))
- ✅ sops-nix configured for secrets management
- ✅ GitHub account for GitOps repository

## Overview

This deployment uses:
- **k3s**: Lightweight Kubernetes as systemd service
- **System PostgreSQL**: Shared database at `192.168.1.165:5432`
- **GitOps**: Automatic deployment from git repository
- **Keycloak**: Centralized authentication (deployed in k3s)

## Deployment Steps

### Step 1: Create Secrets

Create `secrets/k3s.yaml` with required secrets:

```bash
cd /home/zeev/src/nix-config

# Create secrets file
cat > secrets/k3s.yaml <<EOF
tokenFile: $(openssl rand -base64 32)
keycloak_admin_password: $(openssl rand -base64 32)
EOF

# Save the admin password - you'll need it!
echo "Save this password:"
grep keycloak_admin_password secrets/k3s.yaml

# Encrypt with sops
sops -e secrets/k3s.yaml
```

**Note**: `keycloak_db_password` already exists in `secrets/postgresql.yaml`

### Step 2: Create GitOps Repository

Follow [GITOPS-SETUP.md](GITOPS-SETUP.md) to create your GitOps repository:

```bash
# Create repository on GitHub
# URL: https://github.com/4rmcyt/gitops

# Clone and setup
git clone https://github.com/4rmcyt/gitops.git
cd gitops

# Create Keycloak manifests
mkdir -p k3s/keycloak
# ... (see GITOPS-SETUP.md for full manifests)

# Commit and push
git add k3s/
git commit -m "Initial Keycloak deployment"
git push origin main
```

### Step 3: Enable k3s Module

Add k3s to your NixOS configuration:

```nix
# In your configuration.nix or flake
imports = [
  ./modules/services/k3s
];
```

### Step 4: Deploy NixOS Configuration

```bash
sudo nixos-rebuild switch
```

This will:
1. ✅ Install k3s
2. ✅ Start k3s systemd service
3. ✅ Setup GitOps sync service
4. ✅ Create Kubernetes secrets from sops
5. ✅ Clone GitOps repository
6. ✅ Deploy Keycloak manifests

### Step 5: Verify Deployment

```bash
# Check k3s is running
systemctl status k3s

# Check GitOps sync
systemctl status k3s-gitops-sync
journalctl -u k3s-gitops-sync -n 50

# Check pods
kubectl get pods

# Expected output:
# NAME                        READY   STATUS    RESTARTS   AGE
# keycloak-xxxxx              1/1     Running   0          2m

# Check services
kubectl get svc

# Expected output:
# NAME       TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)
# keycloak   LoadBalancer   10.43.x.x     127.0.0.1     9000:xxxxx/TCP

# Check secrets were created
kubectl get secrets

# Expected:
# keycloak-db-config   Opaque   1      2m
# keycloak-admin       Opaque   2      2m
```

### Step 6: Test Keycloak Access

```bash
# Test locally
curl -I http://localhost:9000
# Should return HTTP 200 or redirect

# Test via Cloudflare tunnel
curl -I https://auth.example.com
# Should return HTTP 200 or redirect
```

### Step 7: Access Keycloak Admin Console

1. Navigate to: **https://auth.example.com**
2. Login with:
   - **Username**: `admin`
   - **Password**: (from `k3s_keycloak_admin_password` in secrets/k3s.yaml)

### Step 8: Configure OIDC Clients

Follow [k3s-oidc-setup.md](../../security/keycloak/k3s-oidc-setup.md) to:

1. Create `homelab` realm
2. Configure OIDC clients for services:
   - homepage
   - kavita
   - miniflux
   - atuin
   - microbin
   - oauth2-proxy (for *arr services)

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                  NixOS Homeserver                         │
│                                                           │
│  System Services:                                        │
│  ├─ PostgreSQL (192.168.1.165:5432) ──────┐             │
│  ├─ Nginx                                  │             │
│  ├─ Miniflux                               │             │
│  └─ Other services                         │             │
│                                             │             │
│  k3s (systemd service):                    │             │
│  ├─ API Server :6443                       │             │
│  ├─ Flannel VXLAN :8472                    │             │
│  └─ Keycloak Pod ◄─────────────────────────┘             │
│      └─ LoadBalancer :9000                               │
│                                                           │
│  GitOps Sync (timer: every 5m):                          │
│  └─ https://github.com/4rmcyt/gitops.git                 │
│      └─ k3s/keycloak/*.yaml                              │
│                                                           │
└──────────────────────────────────────────────────────────┘
                        │
                        ▼
              Cloudflare Tunnel
                        │
                        ▼
            https://auth.example.com
```

## GitOps Workflow

### How It Works

1. **Timer**: k3s-gitops-sync.timer runs every 5 minutes
2. **Fetch**: Pulls latest from https://github.com/4rmcyt/gitops.git
3. **Compare**: Checks if git commit changed
4. **Apply**: If changed, runs `kubectl apply -f k3s/ --recursive`
5. **Deploy**: k3s automatically deploys/updates resources

### Making Changes

To update Keycloak (or any app):

```bash
cd ~/gitops

# Edit manifest
vim k3s/keycloak/deployment.yaml
# Change image version, replicas, etc.

# Commit and push
git commit -am "Update Keycloak configuration"
git push

# Changes auto-deployed within 5 minutes!
```

### Manual Sync

To trigger immediate deployment:

```bash
sudo systemctl start k3s-gitops-sync
```

### Monitor Sync

```bash
# Watch logs
journalctl -u k3s-gitops-sync -f

# Check timer
systemctl list-timers k3s-gitops-sync
```

## Port Configuration

No conflicts detected:

### k3s Ports
- **6443**: Kubernetes API
- **8472**: Flannel VXLAN (UDP)
- **9000**: Keycloak LoadBalancer
- **10250**: Kubelet metrics
- **30000-32767**: NodePort range

### Existing Services
All other services run on different ports.

## Managing k3s

### View Resources

```bash
# All resources
kubectl get all

# Specific resources
kubectl get pods
kubectl get services
kubectl get deployments

# With details
kubectl describe pod keycloak-xxxxx
kubectl describe svc keycloak
```

### View Logs

```bash
# Follow logs
kubectl logs deployment/keycloak -f

# Recent logs
kubectl logs deployment/keycloak --tail=100
```

### Execute Commands in Pod

```bash
# Get shell
kubectl exec -it deployment/keycloak -- bash

# Run single command
kubectl exec deployment/keycloak -- env | grep KC_
```

### Update Application

Applications are managed via GitOps:

```bash
# Edit in gitops repo
cd ~/gitops
vim k3s/keycloak/deployment.yaml

# Change image version
# From: image: quay.io/keycloak/keycloak:26.0
# To:   image: quay.io/keycloak/keycloak:27.0

# Commit and push
git commit -am "Update Keycloak to 27.0"
git push

# k3s will perform rolling update automatically
```

## Troubleshooting

### k3s Not Starting

```bash
# Check service
systemctl status k3s
journalctl -u k3s -n 50

# Check PostgreSQL is running
systemctl status postgresql

# Check firewall
sudo nft list ruleset | grep 6443
```

### GitOps Not Syncing

```bash
# Check timer is active
systemctl status k3s-gitops-sync.timer

# View sync logs
journalctl -u k3s-gitops-sync -n 100

# Check git repo
cd /var/lib/k3s-gitops
git status
git log -1

# Manual trigger
sudo systemctl start k3s-gitops-sync
```

### Pods Not Running

```bash
# Check pods
kubectl get pods

# Describe pod to see events
kubectl describe pod keycloak-xxxxx

# Check logs
kubectl logs deployment/keycloak

# Common issues:
# 1. Secrets not created
kubectl get secrets

# 2. Database connection
kubectl exec -it deployment/keycloak -- curl -v postgres://192.168.1.165:5432

# 3. Image pull errors
kubectl describe pod keycloak-xxxxx | grep -A 5 Events
```

### Keycloak Not Accessible

```bash
# Check service has LoadBalancer IP
kubectl get svc keycloak
# EXTERNAL-IP should be 127.0.0.1 or your host IP

# Test locally
curl http://localhost:9000

# Check cloudflared
systemctl status cloudflared
journalctl -u cloudflared -f

# Check firewall allows port 9000
sudo ss -tlnp | grep 9000
```

### Database Connection Errors

```bash
# Verify secret exists
kubectl get secret keycloak-db-config -o yaml

# Test from pod
kubectl run -it --rm debug --image=postgres:16-alpine --restart=Never -- \
  psql -h 192.168.1.165 -U keycloak -d keycloak

# Check PostgreSQL allows connections
sudo -u postgres psql -c "SHOW hba_file;"
sudo cat /var/lib/postgresql/16/pg_hba.conf
```

## Backup and Restore

### Backup Keycloak Data

Since Keycloak uses system PostgreSQL:

```bash
# Backup database
sudo -u postgres pg_dump keycloak > keycloak-backup-$(date +%Y%m%d).sql

# Compressed backup
sudo -u postgres pg_dump keycloak | gzip > keycloak-backup-$(date +%Y%m%d).sql.gz
```

### Restore Keycloak Data

```bash
# Stop Keycloak
kubectl scale deployment keycloak --replicas=0

# Restore database
sudo -u postgres psql keycloak < keycloak-backup-20250101.sql

# Start Keycloak
kubectl scale deployment keycloak --replicas=1
```

## Security Considerations

1. **Secrets**: All stored in sops, never in git
2. **Database**: PostgreSQL uses scram-sha-256 authentication
3. **Network**: Cloudflare tunnel provides SSL/TLS
4. **Firewall**: Only required ports open
5. **Updates**: GitOps allows controlled deployments
6. **Access**: Kubernetes RBAC can be configured

## Next Steps

1. ✅ Configure Keycloak realm
2. ✅ Create OIDC clients ([k3s-oidc-setup.md](../../security/keycloak/k3s-oidc-setup.md))
3. ✅ Integrate services ([service-oidc-examples.nix](../../security/keycloak/service-oidc-examples.nix))
4. ✅ Add more applications via GitOps
5. ✅ Setup monitoring (Prometheus/Grafana in k3s)
6. ✅ Configure backups

## Additional Resources

- [README.md](README.md) - How k3s works
- [GITOPS-SETUP.md](GITOPS-SETUP.md) - GitOps repository setup
- [SUMMARY.md](SUMMARY.md) - Complete overview
- [k3s Documentation](https://docs.k3s.io/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
