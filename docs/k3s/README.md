# How k3s Works in NixOS

## What is k3s?

k3s is a **lightweight Kubernetes distribution** that runs directly on your NixOS system as a **systemd service**. It's NOT a VM or container - it's a native Linux process that manages containers.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Your NixOS System                        │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │               k3s (systemd service)                     │ │
│  │                                                         │ │
│  │  ┌──────────────┐    ┌──────────────┐                 │ │
│  │  │ API Server   │    │  Scheduler   │                 │ │
│  │  └──────────────┘    └──────────────┘                 │ │
│  │  ┌──────────────┐    ┌──────────────┐                 │ │
│  │  │ Controller   │    │   Kubelet    │                 │ │
│  │  └──────────────┘    └──────────────┘                 │ │
│  │                                                         │ │
│  │  Manages:                                              │ │
│  │  ┌─────────────────────────────────────────────────┐  │ │
│  │  │         containerd (container runtime)          │  │ │
│  │  │                                                  │  │ │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐      │  │ │
│  │  │  │Container │  │Container │  │Container │      │  │ │
│  │  │  │Keycloak  │  │Your App  │  │Another   │      │  │ │
│  │  │  └──────────┘  └──────────┘  └──────────┘      │  │ │
│  │  └─────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │        System PostgreSQL (systemd service)             │ │
│  │        Used by: Keycloak, Miniflux, etc.               │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## How It Works

### 1. **k3s as a System Service**

When you enable k3s in your NixOS configuration, it:
- Installs k3s binary via Nix
- Creates systemd service: `k3s.service`
- Starts automatically on boot
- Runs as a native Linux process (not in a VM!)

Check status:
```bash
systemctl status k3s
journalctl -u k3s -f
```

### 2. **Container Runtime: containerd**

k3s includes **containerd** (not Docker) as its container runtime:
- Lightweight container manager
- Runs containers directly on your NixOS host
- Isolated using Linux namespaces and cgroups
- Shares the same kernel as your host system

### 3. **Kubernetes Components**

k3s bundles all Kubernetes components into a single binary:
- **API Server**: REST API for managing cluster (port 6443)
- **Scheduler**: Decides which node runs which pod
- **Controller Manager**: Maintains desired state
- **Kubelet**: Manages containers on the node
- **kube-proxy**: Handles networking

### 4. **Networking**

k3s uses **Flannel** for pod networking:
- Creates a virtual network overlay (VXLAN on UDP port 8472)
- Each pod gets its own IP address
- **LoadBalancer** services (like Keycloak) are exposed via **klipper-lb**:
  - klipper-lb is k3s's built-in load balancer
  - Listens on the host's network interface
  - Forwards traffic to pods
  - Example: Keycloak service port 9000 → pod port 8080

```
External request → localhost:9000 → klipper-lb → Keycloak pod :8080
```

### 5. **Storage**

k3s uses **local-path-provisioner** for storage:
- PersistentVolumeClaims automatically create directories on host
- Default location: `/var/lib/rancher/k3s/storage/`
- Data persists across pod restarts
- Backed by your NixOS filesystem (not separate VM disk)

## Key Differences from Docker/Podman

| Aspect | Docker/Podman | k3s |
|--------|---------------|-----|
| **Runtime** | Docker daemon / Podman | containerd (embedded) |
| **Orchestration** | Docker Compose | Kubernetes |
| **Process** | Separate containers | Managed by Kubernetes |
| **Networking** | Bridge/Host | Flannel CNI |
| **Storage** | Volumes | PersistentVolumeClaims |
| **API** | Docker API | Kubernetes API |
| **Management** | `docker`/`podman` CLI | `kubectl` CLI |

## Resource Usage

k3s is lightweight but does consume resources:
- **Memory**: ~500MB-1GB for k3s itself
- **CPU**: Minimal when idle, scales with workload
- **Disk**: Manifest files, container images
- **Network**: Overlay network for pod communication

Your containers add their own resource usage on top of this.

## Why Use k3s Instead of systemd Services?

### Advantages of k3s:
1. **Declarative Configuration**: Define desired state, k3s maintains it
2. **Self-Healing**: Automatically restarts failed containers
3. **Scaling**: Easy to scale apps (change replicas count)
4. **Rolling Updates**: Zero-downtime deployments
5. **Service Discovery**: Built-in DNS for service-to-service communication
6. **Health Checks**: Liveness and readiness probes
7. **Resource Limits**: CPU/memory quotas per container
8. **GitOps**: Auto-deploy from git repository
9. **Industry Standard**: Kubernetes skills are transferable

### Advantages of systemd Services:
1. **Simpler**: Less abstraction, easier to debug
2. **Less Overhead**: No Kubernetes layer
3. **Direct Integration**: Native NixOS configuration
4. **Better for Single Apps**: Overkill for simple services

## Our Setup

In this configuration:
- **k3s**: Runs Keycloak (and future containerized apps)
- **System services**: Run traditional services (PostgreSQL, Nginx, etc.)
- **Hybrid approach**: Best of both worlds

### Why Keycloak in k3s?

1. **Isolation**: Keycloak runs in its own container
2. **Easy Upgrades**: Just change image version
3. **Resource Control**: Set CPU/memory limits
4. **GitOps**: Auto-deploy updates from git
5. **Future-Ready**: Easy to add more apps

### Why PostgreSQL as System Service?

1. **Performance**: Direct access, no network overhead
2. **Shared**: Used by both k3s apps and system services
3. **Backups**: Easier to backup with system tools
4. **Stability**: Critical infrastructure stays on host

## GitOps Auto-Deployment

The configuration includes automatic deployment from git:

1. **Timer**: Checks git repo every 5 minutes
2. **Sync**: Pulls latest manifests from `k3s-manifests/` directory
3. **Apply**: Automatically applies changes to cluster

To use GitOps:
1. Create directory in your repo: `k3s-manifests/`
2. Add Kubernetes YAML files
3. Push to git
4. k3s automatically deploys changes!

Example workflow:
```bash
# In your nix-config repo
mkdir -p k3s-manifests
cat > k3s-manifests/my-app.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  type: LoadBalancer
  selector:
    app: my-app
  ports:
  - port: 8080
    targetPort: 80
EOF

git add k3s-manifests/
git commit -m "Add my-app deployment"
git push

# Within 5 minutes, k3s automatically deploys your app!
```

## Managing k3s

### View Resources
```bash
kubectl get pods
kubectl get services
kubectl get deployments
kubectl get all
```

### View Logs
```bash
kubectl logs deployment/keycloak
kubectl logs -f deployment/keycloak  # Follow logs
```

### Describe Resources
```bash
kubectl describe pod keycloak-xxxxx
kubectl describe service keycloak
```

### Execute Commands in Pods
```bash
kubectl exec -it deployment/keycloak -- bash
```

### Manually Apply Manifests
```bash
kubectl apply -f manifest.yaml
kubectl delete -f manifest.yaml
```

### Check Resource Usage
```bash
kubectl top nodes
kubectl top pods
```

## Troubleshooting

### k3s not starting
```bash
systemctl status k3s
journalctl -u k3s -n 50
```

### Pods not running
```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Service not accessible
```bash
kubectl get svc
# Check LoadBalancer has EXTERNAL-IP
# For k3s, EXTERNAL-IP should be 127.0.0.1 or your host IP
```

### Database connection issues
```bash
# Check PostgreSQL is accessible from k3s pods
kubectl run -it --rm debug --image=postgres:16-alpine --restart=Never -- \
  psql -h 192.168.1.165 -U keycloak -d keycloak
```

## Summary

k3s runs as a **native systemd service** on your NixOS system:
- ✅ **Not a VM** - runs directly on host
- ✅ **Not Docker** - uses containerd
- ✅ **Lightweight** - single binary, low overhead
- ✅ **Production-ready** - full Kubernetes features
- ✅ **GitOps enabled** - auto-deploy from git
- ✅ **Hybrid setup** - works alongside systemd services

Perfect for homelab use cases where you want Kubernetes features without the complexity of a full cluster!
