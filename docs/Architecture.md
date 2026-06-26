# Architecture

## Overview

NixOS flake for 5 hosts managed as a single repository. Built on **flake-parts** with **import-tree** for automatic module discovery. All hosts share a common base layer; host-specific config lives in `parts/hosts/<name>/`.

## Flake Structure

```
flake.nix                   # Entry point — delegates to flake-parts + import-tree ./parts
infra/tf/                   # Terraform/OpenTofu — Authentik OAuth2 provider provisioning
parts/                      # Auto-imported flake-parts modules
  configurations/nixos.nix  # Defines configurations.nixos option → nixosConfigurations
  hosts/<name>/             # Per-host configuration (flake-parts module)
  shared-nixos-settings.nix # modules.nixos.base — shared nix/sops/substituter settings
  home-manager-integration.nix # modules.nixos.base — HM integration + external NixOS input modules
  home-manager-base.nix     # modules.homeManager.base — sops, overlays, stateVersion
  shared-programs.nix       # modules.nixos.base — common programs (zsh, nh, gnupg) on all hosts
  meta.nix                  # options.meta (stateVersion, owner)
  owner.nix                 # Non-secret owner metadata (username, IPs, domain, timezone)
  schemas.nix               # flake.schemas — flake-schemas + custom topology schema
  topology.nix              # nix-topology SVG diagram generation
  formatting.nix            # treefmt (alejandra, deadnix, statix, shfmt, yamlfmt)
  devshells.nix             # Dev shells: default (justfile tasks), ide
hosts/nixos/<name>/         # NixOS system config + hardware-configuration.nix
home/<name>/                # Home Manager config per host
modules/                    # NixOS/HM modules (NOT auto-imported; referenced by host configs)
secrets/                    # sops-encrypted YAML/binary files
tools/                      # Helper scripts and tooling
```

## Module Layer

Modules are **not** auto-imported. They are referenced explicitly from host configs.

```
modules/
  base/                     # Shared base: logging, msmtp, distributed-builds
  options/                  # Custom options: my.defaults.*, my.network.*, my.security.*
  database/                 # postgresql, redis, couchdb
  monitoring/               # Prometheus + Grafana + Loki + Alloy stack; node-exporter-client;
                            #   Alertmanager + alertmanager-ntfy bridge
  networking/               # ssh, tailscale, traefik, headscale, headplane, cloudflared,
                            #   caddy, dnssec, nfs, nut-client/server, avahi, wireguard
  security/                 # crowdsec, fail2ban, kanidm
  services/                 # Application services: home-assistant, radicale, homepage, miniflux,
                            #   nixarr, atuin-server, dispatcharr, microbin, komf, komga, ntfy,
                            #   k3s (disabled), argocd (disabled)
  containers/               # Podman container support
  disko/                    # Declarative disk layouts per host
  users/                    # Per-user NixOS config (zeev, vk)
  backup/                   # Backup tooling
  dots/                     # Dotfile management
  xdg/                      # XDG portal config (NixOS level: xdg-desktop-portal-gnome + gtk)
  WM/                       # Window manager HM modules
    default.nix             # XDG user dirs (HM level)
    gtk.nix                 # GTK theming
    mime/                   # MIME type associations
    niri/                   # Niri WM: settings, keybinds, startup, windowrules, nvidia, monitors
  GUI/                      # GUI apps: firefox, chrome, chromium, obsidian, mpv, IDE (vscode, zed),
                            #   terminal (ghostty, kitty, wezterm), discord, nautilus, thunderbird,
                            #   virt-manager, waydroid, flatpak, zen-browser, stylix
  TUI/                      # Terminal tools: zsh, zellij, atuin, starship, tmux, tty,
                            #   ai-tools (claude-code, gemini-cli, opencode, beads, mcp, llama-cpp)
  fonts/                    # System font packages + fontconfig defaults
  gaming/                   # Steam + gaming packages
  dev/                      # Developer tools
  nix/                      # Nix daemon config (determinate, lix)
  roles/                    # Role compositions (desktop, server, media-server, monitoring)
                            #   Defines options.roles.{desktop,server,...}.enable flags
                            #   Not imported by any host currently — available for opt-in
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
| `my.hardening.*`     | `security/hardening.nix`      | System hardening + auto-upgrade              |

## Host Wiring

Each `parts/hosts/<name>/configuration.nix` declares a `configurations.nixos.<name>.module`:

```nix
configurations.nixos.homeserver.module = {...}: {
  imports = [
    nixosBase           # ← modules.nixos.base (shared-nixos-settings + HM integration + shared-programs)
    ../../../hosts/nixos/homeserver
    inputs.nixarr.nixosModules.default
  ];
  home-manager.users.zeev.imports = [ ../../../home/homeserver ];
};
```

`configurations/nixos.nix` maps each entry to `lib.nixosSystem`.

### Host → Nix daemon variant

| Host        | Nix daemon                  |
|-------------|-----------------------------|
| desktop     | `modules/nix/lix`           |
| homeserver  | `modules/nix/lix`           |
| wsl         | `modules/nix/lix`           |
| matebook    | `modules/nix/determinate`   |
| gcp-relay   | (base default)              |

## Secrets

All secrets managed by **sops-nix** with age encryption.

- Keys: `/root/.config/sops/age/keys.txt` (NixOS), `~/.config/sops/age/keys.txt` (HM)
- Reference pattern: `config.sops.secrets.<name>.path`
- Secret files: `secrets/*.yaml`, `secrets/*.env`, `secrets/*.json`, `secrets/*.bin`
- Never commit plaintext; never call `sops encrypt` via tooling — give the user the command

## Nix Implementation

**Lix** replaces the standard nix daemon on most hosts (`modules/nix/lix`). Matebook uses **determinate** (`modules/nix/determinate`). Channels disabled. Registry pinned to `inputs.nixpkgs`. IFD enabled.

All hosts get:
- `nix-auth` — `nix auth` subcommand for token management
- `nixos-needsreboot` — checks if a rebuild requires a reboot; runs as activation script

Binary caches (priority order):
1. `4rmcyt.cachix.org` (personal, priority 0)
2. `nix-community.cachix.org`, `cache.nixos.org`, `cache.flox.dev` (priority 1)
3. `llama-cpp.cachix.org`, `noctalia.cachix.org`, `devenv.cachix.org`, `nixpkgs-unfree.cachix.org`
4. Desktop additionally: `cache.nixos-cuda.org`, `cuda-maintainers.cachix.org`

GitHub access token loaded via sops secret `nix_access_token`, written to `/run/nix-access-tokens.conf` by a oneshot systemd service at boot. `NIX_USER_CONF_FILES` points to this file for both the nix daemon and user sessions.

## Package Overlays

No local `overlays/` directory. All overlays come from flake inputs:

- **HM scope** (`parts/home-manager-base.nix`): `mcp-servers-nix`, `nur`, `nix-vscode-extensions`, `noctalia`
- **homeserver NixOS scope** (inline in host config): `ephraim-nur` packages (lazylibrarian, ez_setup, iso639-lang, slskd-api), `homepage-dashboard` pinned to v1.13.1
- **gcp-relay NixOS scope** (inline in host config): `headplane`, `headplane-ssh-wasm` buildPhase patch

## Desktop WM Stack

Desktop and matebook use **niri** as WM with **noctalia-shell** (quickshell-based) as bar/shell.

| File | Purpose |
|------|---------|
| `modules/WM/niri/default.nix` | niri settings, session vars, input/layout |
| `modules/WM/niri/noctalia.nix` | noctalia-shell HM config, matugen templates (zed, materialgram) |
| `modules/WM/niri/binds.nix` | keybindings — uses `qs -c noctalia-shell ipc call` for shell actions |
| `modules/WM/niri/startup.nix` | spawn-at-startup: noctalia-shell, cliphist, wl-clip-persist, xwayland-satellite |
| `modules/WM/niri/windowrules.nix` | floating rules |
| `modules/WM/niri/monitors/desktop.nix` | DP-4 + DP-5: 4K@60Hz, 2× scale, VRR |
| `modules/WM/niri/monitors/matebook.nix` | laptop display config |
| `modules/WM/niri/nvidia.nix` | NVIDIA env vars |
| `modules/WM/default.nix` | XDG user dirs (HM level) |
| `modules/WM/gtk.nix` | GTK theming |
| `modules/WM/mime/` | MIME type associations |
| `modules/xdg/default.nix` | NixOS XDG portals: xdg-desktop-portal-gnome + gtk |

**niri version:** `pkgs.niri` (25.11) via `niri-flake` NixOS module — NOT `niri-flake`'s own stable package.

**niri on desktop:** additionally imports `nirinit.nixosModules.nirinit` + `services.nirinit.enable = true`.

**greetd** auto-logs into Niri session as `owner.username`. Session command logs to `~/.local/state/niri/niri.log`.

**noctalia inputs:**
- `inputs.noctalia` = `github:noctalia-dev/noctalia/legacy-v4`
- `inputs.noctalia-qs` = `github:noctalia-dev/noctalia-qs`
- Exports: `homeModules.default`, `nixosModules.default`, `overlays.default`
- NixOS import: `inputs.noctalia.nixosModules.default` on desktop + matebook
- HM import: `inputs.noctalia.homeModules.default` on desktop + matebook

**Theming:** Stylix (`inputs.stylix`) imported as HM module on desktop only.

## AI Tools (`modules/TUI/ai-tools/`)

All desktop HM imports include this module. Sub-modules:

| Sub-module    | Tool                                                  |
|---------------|-------------------------------------------------------|
| `claude-code` | Claude Code CLI                                       |
| `gemini-cli`  | Gemini CLI                                            |
| `opencode`    | OpenCode                                              |
| `beads`       | Beads                                                 |
| `mcp`         | MCP server configs                                    |
| `llama-cpp`   | Local LLM inference (desktop only, imported directly) |

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

Remote hosts are deployed manually via `nixos-rebuild` over SSH or auto-upgrade. No deploy-rs configuration is active.

| Host       | Method                                                              |
|------------|---------------------------------------------------------------------|
| homeserver | `nixos-rebuild switch --target-host root@homeserver.ts.example.com --flake .#homeserver` |
| matebook   | `nixos-rebuild switch --target-host root@matebook.ts.example.com --flake .#matebook` |
| gcp-relay  | Auto-upgrade daily at 04:00 via `my.hardening.autoUpgrade` (`nixos-rebuild boot`, flake `github:4rmcyt/nix-config#gcp-relay`) |
| desktop    | Local: `nixos-rebuild switch --flake .#desktop`                    |

**ZFS/mount safety:** prefer `nixos-rebuild boot` + reboot over `switch` when config changes affect active mount units. See [Infrastructure.md](Infrastructure.md) ZFS Safety Rules.

## Topology Diagram

`nix build .#topology.x86_64-linux.config.output` generates SVG infrastructure diagrams via **nix-topology**. Includes: desktop, homeserver, matebook, gcp-relay.

## Terraform / OpenTofu

`infra/tf/` manages out-of-band infrastructure state that can't live in Nix:

- **Authentik OAuth2** provider + application objects (currently: Karakeep)
- Remote state backend: GitLab HTTP backend (configured via `remote_state_address` variable)
- Secrets injected at plan time via env vars; never committed

Run: `cd infra/tf && tofu init -backend-config=... && tofu apply`
