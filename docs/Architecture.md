# Architecture

## Overview

NixOS flake for 5 hosts managed as a single repository. Built on **flake-parts** with **import-tree** for automatic module discovery. All hosts share a common base layer; host-specific config lives in `parts/hosts/<name>/`.

## Flake Structure

```
flake.nix                   # Entry point — delegates to flake-parts + import-tree ./parts
infra/tf/                   # Terraform/OpenTofu — Authentik OAuth2 provider provisioning
parts/                      # Auto-imported flake-parts modules
  configurations/nixos.nix  # Defines configurations.nixos option → nixosConfigurations + checks
  hosts/<name>/             # Per-host configuration (flake-parts module)
  shared-nixos-settings.nix # modules.nixos.base — shared nix/sops/substituter settings
  home-manager-integration.nix # flake.modules.nixos.base — HM integration + external modules
  home-manager-base.nix     # flake.modules.homeManager.base — sops, overlays, stateVersion
  meta.nix                  # flake.meta (stateVersion)
  owner.nix                 # Non-secret owner metadata (username, IPs, domain, timezone)
  deploy.nix                # deploy-rs node definitions
  topology.nix              # nix-topology SVG diagram generation
  formatting.nix            # treefmt (alejandra, deadnix, statix, shfmt, yamlfmt)
  devshells.nix             # Dev shell with justfile tasks
hosts/nixos/<name>/         # NixOS system config + hardware-configuration.nix
home/<name>/                # Home Manager config per host
modules/                    # NixOS/HM modules (NOT auto-imported; referenced by host configs)
secrets/                    # sops-encrypted YAML/binary files
```

## Module Layer

Modules are **not** auto-imported. They are referenced explicitly from host configs.

```
modules/
  base/                     # Shared base: logging, msmtp, distributed-builds
  options/                  # Custom options: my.defaults.*, my.network.*, my.security.*
  database/                 # postgresql, redis, couchdb
  monitoring/               # Prometheus + Grafana + Loki + Alloy stack; node-exporter-client
  networking/               # ssh, tailscale, traefik, headscale, headplane, cloudflared,
                            #   caddy, dnssec, nfs, nut-client/server, avahi
  security/                 # crowdsec, fail2ban, kanidm
  services/                 # Application services: nixarr, homepage, miniflux, home-assistant,
                            #   atuin_server, komga, komf, dispatcharr, microbin, ntfy,
                            #   radicale, ollama, vaultwarden, dify, calibre-web
  containers/               # Podman container support
  disko/                    # Declarative disk layouts per host
  users/                    # Per-user NixOS config (zeev, vk)
  backup/                   # Backup tooling
  dots/                     # Dotfile management
  xdg/                      # XDG portal config
  WM/                       # Window managers: niri (binds, startup, windowrules, monitors, nvidia)
                            #   + GTK theming, matugen dynamic colors, xdg portals, mime types
  GUI/                      # GUI apps: firefox, chrome, obsidian, mpv, IDE,
                            #   terminal, discord, nautilus, thunderbird, virt-manager,
                            #   waydroid, chromium, flatpak
  TUI/                      # Terminal tools: zsh, zellij, atuin, starship, tmux,
                            #   ai-tools (claude-code, gemini-cli, opencode, beads, mcp)
  fonts/                    # System font packages + fontconfig defaults
  gaming/                   # Steam + gaming packages
  dev/                      # Developer tools
  nix/                      # Nix daemon config (determinate, lix)
```

## Options System

Global options live in `modules/options/`. Never hardcode values — reference via `config.my.*`.

| Option namespace     | File                          | Purpose                                      |
|----------------------|-------------------------------|----------------------------------------------|
| `my.defaults.*`      | `options/defaults.nix`        | user, email, domain, IPs, timezone, locale   |
| `my.network.*`       | `options/network.nix`         | ports, host addresses                        |
| `my.security.*`      | `options/security.nix`        | security-related options                     |
| `my.traefik.*`       | `networking/traefik/`         | Traefik reverse proxy                        |
| `my.headscale.*`     | `networking/headscale/`       | Headscale coordination server                |
| `my.nodeExporter.*`  | `monitoring/node-exporter-client.nix` | Per-host Prometheus node exporter   |
| `my.unbound.*`       | `networking/unbound/`         | Unbound DNS resolver                         |
| `my.crowdsec.*`      | `security/crowdsec/`          | CrowdSec IDS + bouncer                       |
| `my.hardening.*`     | `security/hardening.nix`        | System hardening + auto-upgrade            |

## Host Wiring

Each `parts/hosts/<name>/configuration.nix` declares a `configurations.nixos.<name>.module`:

```nix
configurations.nixos.homeserver.module = {...}: {
  imports = [
    nixosBase           # ← shared-nixos-settings.nix base
    ../../../hosts/nixos/homeserver
    inputs.nixarr.nixosModules.default
  ];
  home-manager.users.zeev.imports = [ ../../../home/homeserver ];
};
```

`configurations/nixos.nix` maps each entry to `lib.nixosSystem` and creates a `checks` derivation.

## Secrets

All secrets managed by **sops-nix** with age encryption.

- Keys: `/root/.config/sops/age/keys.txt` (all hosts)
- Reference pattern: `config.sops.secrets.<name>.path`
- Secret files: `secrets/*.yaml`, `secrets/*.env`, `secrets/*.json`
- Never commit plaintext; never call `sops encrypt` via tooling

## Nix Implementation

**Lix** replaces the standard nix daemon (`nix.package = pkgs.lixPackageSets.latest.lix`).
Channels disabled. Registry pinned to flake inputs. IFD enabled (`allow-import-from-derivation`).

Binary caches (priority order):
1. `4rmcyt.cachix.org` (personal, priority 0)
2. `nix-community.cachix.org`, `cache.nixos.org`, `cache.lix.systems`
3. CUDA, llama-cpp, noctalia, devenv caches

## Package Overlays

There is no local `overlays/` directory. All overlays come from flake inputs and are applied in `parts/home-manager-base.nix` (HM scope) or inline in host `configuration.nix` files (NixOS scope).

To add a custom package override, add it as an overlay closure in the relevant `nixpkgs.overlays` list — either in `parts/home-manager-base.nix` for HM-wide packages or in `parts/hosts/<name>/configuration.nix` for a host-specific NixOS package.

## Desktop WM Stack

Desktop and matebook use **niri** as WM with **noctalia-shell** (quickshell-based) as bar/shell. DMS is not used.

| File | Purpose |
|------|---------|
| `modules/WM/niri/default.nix` | niri settings, session vars, input/layout |
| `modules/WM/niri/noctalia.nix` | noctalia-shell HM config, matugen templates (zed, materialgram) |
| `modules/WM/niri/binds.nix` | keybindings — uses `qs -c noctalia-shell ipc call` for shell actions |
| `modules/WM/niri/startup.nix` | spawn-at-startup: noctalia-shell, cliphist, wl-clip-persist, xwayland-satellite |
| `modules/WM/niri/windowrules.nix` | floating rules |
| `modules/WM/niri/monitors/` | DP-4 and DP-5: 4K@60Hz, 2× scale, VRR (desktop.nix + matebook.nix) |
| `modules/WM/niri/nvidia.nix` | NVIDIA env vars |

**niri version:** `pkgs.niri` (25.11) via `niri-flake` NixOS module — NOT `niri-flake`'s own stable package.

**noctalia inputs:**
- `inputs.noctalia` = `github:noctalia-dev/noctalia/legacy-v4`
- Exports: `homeModules.default`, `nixosModules.default`, `overlays.default`
- NixOS import: `inputs.noctalia.nixosModules.default` on desktop + matebook
- HM import: `inputs.noctalia.homeModules.default` on desktop + matebook

**greetd** auto-logs into Niri session as `owner.username`. Session command logs to `~/.local/state/niri/niri.log`.

## Critical Patterns

### Verify daemon config keys before writing

Before writing any key for a daemon config file (bluetoothd `main.conf`, pipewire, wireplumber, etc.):
1. Check the actual config schema in the store: `find /nix/store -name "*.conf" -path "*<pkg>*" | head`
2. Or check the binary's `--help`

Example: `DisablePlugins` is **not** a valid `main.conf` key for bluetoothd — it's a CLI flag `-P`. Use `systemd.services.bluetooth.serviceConfig.ExecStart` override instead.

### journalctl warnings are not "expected"

Every warning and error in `journalctl -b 0 -p warning` is worth investigating. Do not dismiss as "harmless" — present findings and let the user decide.

## Formatting

`nix fmt` runs **treefmt** with: alejandra (Nix), deadnix (unused bindings), statix (antipatterns), prettier (JSON/YAML/MD), shfmt (shell), yamlfmt (YAML).

## Deployment

**deploy-rs** manages remote hosts. `nix run .#deploy -- .#<host>`.

| Host       | Magic rollback | Auto rollback |
|------------|---------------|---------------|
| homeserver | yes           | yes           |
| matebook   | yes           | yes           |
| gcp-relay  | yes           | yes           |
| desktop    | no (local)    | no            |

GCP relay additionally auto-upgrades itself daily at 04:00 via `my.hardening.autoUpgrade`.

## Topology Diagram

`nix build .#topology.x86_64-linux.config.output` generates SVG infrastructure diagrams via **nix-topology**.

## Terraform / OpenTofu

`infra/tf/` manages out-of-band infrastructure state that can't live in Nix:

- **Authentik OAuth2** provider + application objects (currently: Karakeep)
- Remote state backend: GitLab HTTP backend (configured via `remote_state_address` variable)
- Secrets injected at plan time via env vars; never committed

Run: `cd infra/tf && tofu init -backend-config=... && tofu apply`
