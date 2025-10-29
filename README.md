# NixOS Configuration

Personal NixOS configuration using flakes for multiple systems.

## 🖥️ Systems

### Desktop
- **OS**: NixOS with KDE Plasma 6
- **Graphics**: NVIDIA GPU with Wayland
- **Boot**: Secure boot with lanzaboote
- **Use case**: Gaming and workstation

### Homeserver
- **OS**: NixOS
- **Services**: Media server (Jellyfin, *arr stack), monitoring (Prometheus, Grafana), databases (PostgreSQL)
- **Use case**: Home lab and self-hosted services

### Laptop
- **OS**: NixOS with GNOME
- **Graphics**: AMD GPU
- **Features**: Power management, portable system

### WSL
- **OS**: NixOS under Windows Subsystem for Linux
- **Use case**: Development on Windows

## 📁 Repository Structure

```
.
├── flake.nix              # Main flake configuration
├── flakeHelpers.nix       # Helper functions for system configuration
├── hosts/
│   └── nixos/
│       ├── desktop/       # Desktop system configuration
│       ├── homeserver/    # Homeserver configuration
│       ├── laptop/        # Laptop configuration
│       └── wsl/           # WSL configuration
├── modules/
│   ├── base/              # Base system modules & nix settings
│   ├── roles/             # Role-based system abstractions (NEW!)
│   ├── options/           # Centralized configuration options (NEW!)
│   ├── GUI/               # GUI applications and settings
│   ├── database/          # Database services (PostgreSQL)
│   ├── disko/             # Disk partitioning configurations
│   ├── gaming/            # Gaming-related packages and settings
│   ├── monitoring/        # Monitoring stack (Prometheus, Grafana)
│   ├── networking/        # Network configuration (Tailscale, DNSSEC, nginx)
│   ├── security/          # Security modules (authentik, fail2ban)
│   ├── services/          # Various self-hosted services
│   ├── containers/        # Container configurations (Podman)
│   ├── plasma/            # KDE Plasma configuration
│   └── users/             # User configurations
├── home-manager/          # Home Manager configurations per host
│   ├── shared/            # Shared home-manager modules
│   ├── desktop/
│   ├── homeserver/
│   ├── laptop/
│   └── wsl/
└── secrets/               # SOPS encrypted secrets

```

## 🚀 Getting Started

### Prerequisites

- NixOS installed (or WSL for Windows)
- Git configured
- SOPS keys set up for secrets management

### Initial Setup

1. Clone the repository:
```bash
git clone https://github.com/4rmcyt/nix-config.git
cd nix-config
```

2. Set up SOPS age keys:
```bash
mkdir -p ~/.config/sops/age
# Add your age key to ~/.config/sops/age/keys.txt
```

3. Build and switch to configuration:
```bash
# For NixOS systems
sudo nixos-rebuild switch --flake .#<hostname>

# For home-manager only (Darwin)
home-manager switch --flake .#<hostname>
```

Where `<hostname>` is one of: `desktop`, `homeserver`, `laptop`, or `wsl`

## 🔧 Key Features

### 🎭 Role-Based System Abstraction (NEW!)
- **Server Role**: Common server configurations (SSH, security, no GUI)
- **Desktop Role**: GUI, audio, printing, user-focused settings
- **Media Server Role**: Media directories, BitTorrent, media groups
- **Monitoring Role**: Prometheus, Grafana, observability stack
- Composable roles for clean host configurations

### 🌐 Centralized Network Management (NEW!)
- Complete network topology in code
- All devices documented (25+ devices)
- Service ports centralized (30+ services)
- IP addresses managed in one place
- See `modules/options/network.nix`

### 🔄 Distributed Builds (NEW!)
- Build sharing between desktop and homeserver
- Automatic load balancing
- Speed up compilation with remote cores
- See `docs/distributed-builds.md` for setup

### 🤖 CI/CD with GitHub Actions (NEW!)
- Automated flake checking
- Format validation
- Build testing for all configurations
- Nix store caching for faster CI

### Secrets Management
- Uses [SOPS](https://github.com/Mic92/sops-nix) for encrypted secrets
- Age keys stored in `~/.config/sops/age/keys.txt`
- Secrets organized by service in `secrets/` directory

### Disk Management
- [Disko](https://github.com/nix-community/disko) for declarative disk partitioning
- Separate configurations per host in `modules/disko/`

### Home Manager
- User-level package management and dotfiles
- Shared configurations in `home-manager/shared/`
- Per-host customizations

### Monitoring
- Prometheus for metrics collection
- Grafana for visualization
- Node exporter and service-specific exporters

### Self-hosted Services
Homeserver runs various services including:
- **Media**: Jellyfin, Sonarr, Radarr, Prowlarr, Bazarr
- **Auth**: Authentik
- **Monitoring**: Prometheus, Grafana, Uptime Kuma
- **Database**: PostgreSQL 16
- **Containers**: Podman with various containerized services

### Security
- SOPS encrypted secrets
- Fail2ban for intrusion prevention
- Secure boot on desktop (lanzaboote)
- Tailscale for secure remote access
- PostgreSQL with scram-sha-256 authentication

## 🛠️ Common Tasks

### Update System
```bash
nix flake update
sudo nixos-rebuild switch --flake .#<hostname>
```

### Update Specific Input
```bash
nix flake lock --update-input <input-name>
```

### Add New Service
1. Create module in appropriate directory under `modules/`
2. Use `modules/services/_template/default.nix` as reference
3. Import module in host configuration
4. Add secrets if needed in `secrets/`

### Format Code
```bash
nix fmt
```

## 📝 Notes

- System state version: 25.05 (most systems)
- Username: Configured via `flakeHelpers.nix`
- Domain for homeserver: `example.com`
- Timezone: America/Edmonton

## 🔐 Security Considerations

- Secrets are encrypted with SOPS
- Age keys should be backed up securely
- SSH keys are managed per-user
- PostgreSQL uses peer authentication for local connections and password authentication for network connections

## 📚 Documentation

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Flakes](https://nixos.wiki/wiki/Flakes)
- [SOPS-nix](https://github.com/Mic92/sops-nix)

## 🤝 Contributing

This is a personal configuration repository, but feel free to use it as inspiration for your own setup!

## 📄 License

Personal configuration - use at your own discretion.
