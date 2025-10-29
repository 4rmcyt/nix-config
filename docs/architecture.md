# NixOS Configuration Architecture

This document explains the architecture and design decisions of this NixOS configuration.

## Overview

This configuration follows a **layered architecture** with clear separation of concerns:

1. **Base Layer**: Common system settings
2. **Roles Layer**: Composable system roles
3. **Options Layer**: Centralized configuration values
4. **Host Layer**: Per-host specific configurations
5. **Home Manager Layer**: User-level configurations

## Architecture Layers

### 1. Base Layer (`modules/base/`)

Provides fundamental system configuration that applies to all hosts:

- **nix-settings.nix**: Common Nix daemon settings (flakes, substituters, cores)
- **auto_upgrade**: Automatic system updates
- **logging**: System logging configuration
- **distributed-builds.nix**: Distributed build capabilities
- **msmtp**: Email sending configuration

**Philosophy**: Minimal, essential settings that every system needs.

### 2. Roles Layer (`modules/roles/`)

Composable system roles that bundle related configurations:

#### Server Role (`roles.server.enable`)
- SSH hardening (no passwords, no root login)
- No GUI packages
- Clean `/tmp` on boot
- Suitable for: homeserver, build machines

#### Desktop Role (`roles.desktop.enable`)
- **X Server enabled** for XWayland compatibility
- PipeWire audio stack
- Bluetooth, printing, power management
- Common CLI utilities
- **Important**: Does NOT include desktop environment (DE) or display manager
- Suitable for: desktop, laptop

**Why X Server in Desktop Role?**
Even on Wayland-first systems (Plasma 6, GNOME), X Server is needed for:
- XWayland: Running X11-only applications
- Legacy app compatibility
- Some system utilities expect X11

The actual DE (Plasma, GNOME) is configured in **host configs**, not in roles:
```nix
# In hosts/nixos/desktop/default.nix
services.desktopManager.plasma6.enable = true;
services.displayManager.sddm = {
  enable = true;
  wayland.enable = true;
};
```

#### Media Server Role (`roles.media-server.enable`)
- Inherits server role
- Media directories (`/data/media/*`)
- Media group management
- BitTorrent port ranges

#### Monitoring Role (`roles.monitoring.enable`)
- Inherits server role
- Prometheus & Grafana setup
- Monitoring directories
- Observability firewall rules

**Usage Example**:
```nix
# homeserver
roles.server.enable = true;
roles.media-server.enable = true;
roles.monitoring.enable = true;

# desktop
roles.desktop.enable = true;
```

### 3. Options Layer (`modules/options/`)

Centralized configuration values - single source of truth:

#### defaults.nix
```nix
my.defaults = {
  user = "zeev";
  email = "4rmcyt@gmail.com";
  domain = "labhome.work";
  timezone = "America/Edmonton";
  # ...
};
```

#### network.nix
Complete network topology:
```nix
my.network = {
  hosts.homeserver = "192.168.1.165";
  hosts.desktop-lan = "192.168.1.118";

  smart-home.plugs.office = "192.168.1.74";

  ports.jellyfin = 8096;
  ports.prometheus = 9090;
  # ... 30+ services
};
```

#### security.nix
```nix
my.security.ssl = {
  certPath = "/var/lib/acme/labhome.work/fullchain.pem";
  keyPath = "/var/lib/acme/labhome.work/key.pem";
};
```

**Benefits**:
- Change IP once, updates everywhere
- Type-safe configuration
- Self-documenting infrastructure
- No hardcoded values

### 4. Host Layer (`hosts/nixos/*/`)

Per-host specific configurations:

```
hosts/nixos/
├── desktop/
│   ├── default.nix          # Main config
│   ├── hardware-configuration.nix  # Auto-generated hardware
│   └── facter.json          # Hardware facts
├── homeserver/
├── laptop/
└── wsl/
```

**Host configs should**:
- Enable appropriate roles
- Configure desktop environment
- Set hardware-specific options
- Override role defaults if needed

**Example** (`hosts/nixos/desktop/default.nix`):
```nix
{
  # Enable roles
  roles.desktop.enable = true;

  # Desktop environment (not in role!)
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Hardware-specific
  services.xserver.videoDrivers = ["nvidia"];

  # Nix settings (override role defaults)
  nix.settings = {
    cores = 12;
    max-jobs = 12;
  };
}
```

### 5. Home Manager Layer (`home-manager/`)

User-level configurations and dotfiles:

```
home-manager/
├── shared/
│   ├── common.nix    # Programs available to all users
│   ├── zsh.nix       # Shell configuration
│   └── tmux.nix      # Terminal multiplexer
├── desktop/          # Desktop-specific home config
├── homeserver/
├── laptop/
└── wsl/
```

**Home Manager manages**:
- User packages
- Dotfiles (shell, git, vim, etc.)
- User services (systemd --user)
- GUI application configs (Firefox, Thunderbird)

## GUI Applications Management

GUI applications are **NOT** in the desktop role. They're managed separately:

### System-level (NixOS)
Located in `modules/GUI/`:
- **OBS** (`modules/GUI/OBS/`): Uses `programs.obs-studio`
- **Flatpak** (`modules/GUI/flatpak/`): Flatpak support

### User-level (Home Manager)
Located in `modules/GUI/` but applied via home-manager:
- **Firefox** (`modules/GUI/firefox/`): Uses `programs.firefox`
- **Thunderbird** (`modules/GUI/thunderbird/`): Uses `programs.thunderbird` + `accounts.email`
- **Zen Browser** (`modules/GUI/zen-browser/`)

**Why separate?**
- System packages: Available to all users, system services
- Home Manager: Per-user customization, dotfiles, profiles

**Pattern**:
```nix
# In home-manager/desktop/default.nix
imports = [
  ../../modules/GUI/firefox
  ../../modules/GUI/thunderbird
];
```

## Wayland vs X11 Strategy

### Current Setup
- **Desktop**: Plasma 6 + Wayland (primary), XWayland (fallback)
- **Laptop**: GNOME + Wayland (planned), XWayland (fallback)

### X Server Configuration
```nix
# In roles/desktop.nix
services.xserver.enable = lib.mkDefault true;
```

This is **correct** because:
1. **XWayland requires X Server**: Even pure Wayland sessions need X server for XWayland
2. **X11 apps work**: Legacy applications run via XWayland
3. **Compatibility**: Some system tools expect X11 libraries

### Wayland-First Setup
```nix
# Host config (desktop/laptop)
services.desktopManager.plasma6.enable = true;  # Wayland-native
services.displayManager.sddm.wayland.enable = true;

# Session variables (for Wayland apps)
environment.sessionVariables = {
  GDK_BACKEND = "wayland,x11";
  MOZ_ENABLE_WAYLAND = "1";
  SDL_VIDEODRIVER = "wayland";
};
```

X11 apps automatically use XWayland, no additional configuration needed.

## Network Management

All network configuration centralized in `modules/options/network.nix`:

### Device Inventory
- Gateway: Router (192.168.1.254)
- Servers: homeserver, desktop
- Smart home: 5+ smart plugs, humidifier, Echo Show
- Entertainment: Roku TV, PS5, Nintendo Switch, Mi Box
- Mobile: 2 phones
- Network switches: Office, Living Room

### Service Ports
30+ services with centralized port definitions:
- Media: Jellyfin (8096), Transmission (9091), etc.
- *arr Stack: Sonarr (8989), Radarr (7878), etc.
- Monitoring: Prometheus (9090), Grafana (3003)
- Home: Home Assistant (8123), Paperless (8888)

### Usage in Configs
```nix
# Instead of hardcoded
"jellyfin.labhome.work" = "http://localhost:8096";

# Use centralized
"jellyfin.labhome.work" = "http://localhost:${toString config.my.network.ports.jellyfin}";
```

**Benefits**:
- Single source of truth
- Easy port changes
- No conflicts
- Self-documenting

## Secrets Management

Using [SOPS](https://github.com/Mic92/sops-nix) with age encryption:

```nix
sops.secrets.service_password = {
  sopsFile = ../../secrets/service.yaml;
  key = "password";
  owner = config.users.users.service.name;
  mode = "0400";
};
```

**Keys location**: `~/.config/sops/age/keys.txt`

## Build System

### Distributed Builds
Share build load between desktop and homeserver:

```nix
distributed-builds = {
  enable = true;
  role = "both";
  builders = [{
    hostName = config.my.network.hosts.homeserver;
    maxJobs = 8;
    speedFactor = 2;
  }];
};
```

See [docs/distributed-builds.md](./distributed-builds.md) for setup.

### CI/CD
GitHub Actions validate all configurations:
- Flake checking
- Format validation
- Build testing (all 4 hosts)
- Nix store caching

## Module Organization

### When to create a module?
- **Service module** (`modules/services/`): Complete service configuration
- **GUI module** (`modules/GUI/`): GUI application with home-manager
- **Role** (`modules/roles/`): Bundle of related system configs
- **Option** (`modules/options/`): Shared configuration values

### Module template
See `modules/services/_template/default.nix` for service module example.

## Design Principles

### 1. DRY (Don't Repeat Yourself)
- Centralize common values (network, defaults)
- Use roles for repeated patterns
- Compose instead of duplicate

### 2. Explicit over Implicit
- Clear role names (`roles.desktop.enable`)
- Documented decisions (comments in configs)
- Type-safe options

### 3. Separation of Concerns
- Base: system essentials
- Roles: composable bundles
- Hosts: specific configurations
- Home Manager: user configs

### 4. Least Surprise
- Roles provide sensible defaults
- Host configs override when needed
- Clear documentation of choices

### 5. Maintainability
- Single source of truth
- Clear module boundaries
- Comprehensive documentation

## Common Patterns

### Adding a New Host
```nix
# 1. Create host directory
mkdir -p hosts/nixos/newhost

# 2. Create default.nix
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/base
    ../../../modules/users/zeev
  ];

  # Enable role
  roles.desktop.enable = true;  # or roles.server.enable

  # Desktop environment (if desktop)
  services.desktopManager.plasma6.enable = true;

  # Hardware-specific configs
  # ...
}

# 3. Add to flake.nix
nixosConfigurations.newhost = helpers.mkHost {
  modules = [ ./hosts/nixos/newhost ];
};
```

### Adding a New Service
```nix
# modules/services/myservice/default.nix
{config, pkgs, ...}: {
  # Secrets
  sops.secrets.myservice_password = { ... };

  # User
  users.users.myservice = { ... };

  # Firewall
  networking.firewall.allowedTCPPorts = [
    config.my.network.ports.myservice  # Use centralized port!
  ];

  # Service
  services.myservice = { ... };
}
```

## Troubleshooting

### Flake evaluation errors
```bash
nix flake check --show-trace
```

### Build a specific host
```bash
nix build .#nixosConfigurations.desktop.config.system.build.toplevel
```

### Format check
```bash
nix fmt -- --check .
```

## References

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [SOPS-nix](https://github.com/Mic92/sops-nix)

## Summary

This architecture provides:
- ✅ **Clean separation** of system, role, and user configs
- ✅ **Composable roles** for quick host setup
- ✅ **Centralized values** for easy maintenance
- ✅ **Wayland-first** with X11 compatibility
- ✅ **Type safety** and validation
- ✅ **Self-documenting** infrastructure
- ✅ **CI/CD** integration
- ✅ **Distributed builds** capability

A production-ready, scalable foundation for managing home infrastructure! 🚀
