# k3s Security Enhancements - GitOps Examples

These files should be added to your GitOps repository at https://github.com/4rmcyt/gitops.git

## Files to Add

### 1. Network Policies
**Location**: `k3s/network-policies/default-deny.yaml`
**Source**: Copy from `network-policy-default-deny.yaml`

This implements:
- Default deny-all policy (blocks all traffic by default)
- Explicit allow for Keycloak → PostgreSQL
- Explicit allow for LoadBalancer → Keycloak
- DNS resolution allowed

### 2. Resource Quotas
**Location**: `k3s/quotas/default-quota.yaml`
**Source**: Copy from `resource-quota.yaml`

This implements:
- Namespace-wide resource limits (CPU, memory, pods, storage)
- Default resource requests/limits for containers
- Prevents resource exhaustion attacks

## How to Apply

```bash
# Navigate to your gitops repository
cd ~/gitops  # or wherever you cloned it

# Create directories
mkdir -p k3s/network-policies
mkdir -p k3s/quotas

# Copy files
cp /path/to/nix-config/modules/services/k3s/gitops-examples/network-policy-default-deny.yaml k3s/network-policies/default-deny.yaml
cp /path/to/nix-config/modules/services/k3s/gitops-examples/resource-quota.yaml k3s/quotas/default-quota.yaml

# Commit and push
git add k3s/network-policies/ k3s/quotas/
git commit -m "security: Add NetworkPolicies and ResourceQuotas

- Add default-deny NetworkPolicy with explicit allows for Keycloak
- Add ResourceQuota to prevent resource exhaustion
- Add LimitRange for default container limits"
git push origin main

# Changes will be auto-applied within 5 minutes
# Or trigger manual sync:
sudo systemctl start k3s-gitops-sync
```

## Verify Deployment

```bash
# Check NetworkPolicies
kubectl get networkpolicies -n default

# Expected output:
# NAME                       POD-SELECTOR   AGE
# default-deny-all          <none>         1m
# keycloak-allow-egress     app=keycloak   1m
# keycloak-allow-ingress    app=keycloak   1m

# Check ResourceQuotas
kubectl get resourcequota -n default

# Expected output:
# NAME            AGE     REQUEST                                                   LIMIT
# default-quota   1m      pods: 1/20, requests.cpu: 250m/4, requests.memory: ...    ...

# Check LimitRanges
kubectl get limitrange -n default

# Expected output:
# NAME                  CREATED AT
# default-limit-range   2025-01-01T00:00:00Z
```

## Troubleshooting

### Pods fail to start after applying NetworkPolicies
If Keycloak can't connect to PostgreSQL:

1. Check NetworkPolicy logs:
   ```bash
   kubectl describe networkpolicy keycloak-allow-egress
   ```

2. Verify pod labels match the policy:
   ```bash
   kubectl get pod -l app=keycloak --show-labels
   ```

3. Test connectivity from pod:
   ```bash
   kubectl exec -it deployment/keycloak -- curl -v telnet://192.168.1.165:5432
   ```

### ResourceQuota prevents deployment
If you see "exceeded quota" errors:

1. Check current usage:
   ```bash
   kubectl describe resourcequota default-quota
   ```

2. Temporarily increase limits in `k3s/quotas/default-quota.yaml`:
   ```yaml
   spec:
     hard:
       requests.cpu: "8"    # Increased from 4
       limits.cpu: "16"     # Increased from 8
   ```

3. Commit and push changes

## Security Impact

### NetworkPolicies
- **Before**: Any pod could connect to any other pod/service
- **After**: Only explicitly allowed connections work
- **Impact**: Limits lateral movement in case of container compromise

### ResourceQuotas
- **Before**: Pods could request unlimited resources
- **After**: Namespace-wide limits enforced
- **Impact**: Prevents DoS via resource exhaustion

## Additional Security Recommendations

### 1. Enable GPG Commit Signing
Protect against compromised GitHub account:

```bash
# Setup GPG key
gpg --full-generate-key

# Configure git
git config user.signingkey <KEY_ID>
git config commit.gpgsign true

# Sign commits
git commit -S -m "message"
```

Then update k3s GitOps service to verify signatures.

### 2. Use Private Repository
Make your GitOps repo private and use SSH deploy keys:

```bash
# Generate deploy key
ssh-keygen -t ed25519 -f ~/.ssh/gitops-deploy-key -N ""

# Add to GitHub as read-only deploy key
cat ~/.ssh/gitops-deploy-key.pub

# Update k3s config to use SSH URL
# gitOpsRepo = "git@github.com:4rmcyt/gitops.git";
```

### 3. Enable PostgreSQL SSL
Encrypt database connections:

In PostgreSQL configuration, enable SSL and update Keycloak deployment:
```yaml
env:
  - name: KC_DB_URL
    value: "jdbc:postgresql://192.168.1.165:5432/keycloak?ssl=true&sslmode=require"
```

## Related Documentation

- [DEPLOYMENT.md](../DEPLOYMENT.md) - Main deployment guide
- [SUMMARY.md](../SUMMARY.md) - Complete k3s overview
- [Kubernetes NetworkPolicies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Kubernetes Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
