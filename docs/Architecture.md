# Architecture

## Overview

NixOS flake for 5 hosts managed as a single repository. Built on **flake-parts** with **import-tree** for automatic module discovery. All hosts share a common base layer; host-specific config lives in `parts/hosts/<name>/`.

## Flake Structure

```
flake.nix                   # Entry point — delegates to flake-parts + import-tree ./parts
infra/tf/gcp-relay/         # Terraform/OpenTofu — GCP infrastructure for gcp-relay (static IP, GCS bucket, VM instance)
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
  networking/               # ssh, tailscale, traefik, headscale, cloudflared,
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
    mango/                  # mango WM (desktop): settings, keybinds, startup, windowrules, nvidia, monitors
    niri/                   # niri WM (matebook): settings, keybinds, startup, windowrules, nvidia, monitors
    hyprland/               # unused — kept on disk, no longer imported by any host
  GUI/                      # GUI apps: firefox, chrome, chromium, obsidian, mpv, IDE (vscode, zed),
                            #   terminal (ghostty, kitty, wezterm), discord, nemo, thunderbird,
                            #   virt-manager, waydroid, flatpak, stylix
  TUI/                      # Terminal tools: zsh, zellij, atuin, starship, tmux, tty, neovim,
                            #   ai-tools (claude-code, antigravity-cli, mcp, llama-cpp)
                            #   ai-tools sub-dirs: agents/, skills/, commands/, system-prompt/
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

- **HM scope** (`parts/home-manager-base.nix`): `mcp-servers-nix`, `nur`, `nix-vscode-extensions`, `noctalia`; also patches `mcp-server-fetch` (proxy API fix)
- **homeserver NixOS scope** (inline in host config): `ephraim-nur` packages (lazylibrarian, ez_setup, iso639-lang, slskd-api), `homepage-dashboard` pinned to v1.13.1

## Desktop WM Stack

**Desktop uses mango; matebook uses niri.** Both pair with **noctalia** v5 (native C++ binary, no Quickshell) as bar/shell. Desktop ran Hyprland until 2026-08-22, when it was fully replaced by mango (`modules/WM/hyprland/` is kept on disk but no longer imported by any host, and was not migrated off noctalia legacy-v4 — see below).

### mango (desktop only)

| File | Purpose |
|------|---------|
| `modules/WM/mango/default.nix` | mango settings (structured Nix → `config.conf`), session vars, qt theming, scroller layout, blur/shadow effects |
| `modules/WM/mango/noctalia.nix` | noctalia HM config |
| `modules/WM/mango/binds.nix` | keybindings (`bind`/`mousebind` in mango's own comma-separated grammar) |
| `modules/WM/mango/startup.nix` | `autostart_sh`: cliphist, wl-clip-persist, noctalia, materialgram, vesktop, coolercontrol |
| `modules/WM/mango/windowrules.nix` | floating rules (`windowrule=` strings) |
| `modules/WM/mango/monitors/desktop.nix` | ASUS VG289 ×2, 4K@60Hz, 2× scale, matched by make+model+serial (`monitorrule=`) |
| `modules/WM/mango/nvidia.nix` | NVIDIA env vars (`LIBVA_DRIVER_NAME`, GSync/VRR, `GLVidHeapReuseRatio` app profile), set both via HM sessionVariables and mango's own `env=` config lines |

**mango version:** `inputs.mango` (`github:mangowm/mango`) — provides `nixosModules.mango` (`programs.mango.enable`) and `hmModules.mango` (`wayland.windowManager.mango`), not the nixpkgs package.

**greetd** on desktop execs `mango` directly (no UWSM — mango's own HM module binds a `mango-session.target` to `graphical-session.target` itself).

**No real HDR on desktop's mango build:** mango does support HDR (`hdr:1`/`hdr_force`/`hdr_*_lum` in `monitorrule`), but only on its separate wl-only branch behind `WLR_RENDERER=vulkan` — and that branch drops scenefx (blur/shadow effects), which `modules/WM/mango/default.nix` relies on. nixpkgs/`inputs.mango` builds the mainline (non-vulkan) branch, so HDR isn't reachable there regardless. Niri has no HDR path at all (see below); Hyprland ≥0.55 was the only WM in this config with a working HDR10 output path (`wp_color_management v2`) before the switch.

### niri (matebook only)

| File | Purpose |
|------|---------|
| `modules/WM/niri/default.nix` | niri settings, session vars, input/layout |
| `modules/WM/niri/noctalia.nix` | noctalia HM config, `[theme.templates.user.*]` (zed, materialgram) |
| `modules/WM/niri/binds.nix` | keybindings — `a.spawn "noctalia" "msg" ...` for shell actions |
| `modules/WM/niri/startup.nix` | spawn-at-startup: noctalia, cliphist, wl-clip-persist, xwayland-satellite |
| `modules/WM/niri/windowrules.nix` | floating rules |
| `modules/WM/niri/monitors/matebook.nix` | laptop display config |
| `modules/WM/niri/nvidia.nix` | NVIDIA env vars |

**niri version:** `pkgs.niri` (25.11) via `niri-flake` NixOS module — NOT `niri-flake`'s own stable package.

**greetd** auto-logs into Niri session on matebook as `owner.username`. Session command logs to `~/.local/state/niri/niri.log`.

**No real HDR on niri:** it lacks `wp_color_management v2` — no HDR output path to the display, unlike Hyprland.

### Shared

| File | Purpose |
|------|---------|
| `modules/WM/default.nix` | XDG user dirs (HM level) |
| `modules/WM/gtk.nix` | GTK theming |
| `modules/WM/mime/` | MIME type associations |
| `modules/xdg/default.nix` | NixOS XDG portals: xdg-desktop-portal-gnome + gtk |

**noctalia inputs:**
- `inputs.noctalia` = `github:noctalia-dev/noctalia/cachix` (v5, C++ rewrite — pinned to the `cachix` branch, which always points at the latest commit noctalia's own CI has finished pushing to `noctalia.cachix.org`, so it never forces a local compile the way tracking `main` directly can)
- Migrated from `legacy-v4` (QML/Quickshell, archived upstream) on 2026-08-23. No settings migration from v4 — separate config format (TOML, `[theme.templates.user.*]` instead of `programs.noctalia-shell.user-templates`). IPC CLI changed from `noctalia-shell ipc call <target> <action>` to `noctalia msg <command> [args...]`; command names changed too (e.g. `launcher toggle` → `panel-toggle launcher`, `darkMode toggle` → `theme-mode-toggle`). No v5 equivalent exists for the old standalone color-picker toggle bind (dropped from mango/niri binds).
- Package renamed `noctalia-shell` → `noctalia`; overlay attr is `pkgs.noctalia`.
- No more `noctalia-qs` or `inputs.quickshell` inputs — v5 has no Quickshell dependency at all (removed from flake.nix).
- Exports: `homeModules.default`, `nixosModules.default`, `overlays.default`
- NixOS import: `inputs.noctalia.nixosModules.default` on desktop + matebook
- HM import: `inputs.noctalia.homeModules.default` on desktop + matebook
- `modules/WM/hyprland/*` was NOT migrated (dead code, not imported by any host) — still references `programs.noctalia-shell` and the old IPC syntax. Update it first if hyprland is ever revived.

**Theming:** Stylix (`inputs.stylix`) imported as HM module on desktop only.

## AI Tools (`modules/TUI/ai-tools/`)

All desktop HM imports include this module. Sub-modules:

| Sub-module         | Tool                                                                                      |
| ------------------ | ----------------------------------------------------------------------------------------- |
| `claude-code`       | Claude Code CLI                                                                           |
| `antigravity-cli`   | Antigravity CLI (`agy`) — replaced Gemini CLI (nixpkgs `gemini-cli` flagged for removal)   |
| `mcp`               | MCP server configs (stdio + HTTP with sops secrets)                                       |
| `llama-cpp`         | Local LLM inference (desktop only, imported directly)                                     |

## Critical Patterns

### Verify daemon config keys before writing

Before writing any key for a daemon config file (bluetoothd `main.conf`, pipewire, wireplumber, etc.):
1. Check the actual config schema in the store: `find /nix/store -name "*.conf" -path "*<pkg>*" | head`
2. Or check the binary's `--help`

Example: `DisablePlugins` is **not** a valid `main.conf` key for bluetoothd — it's a CLI flag `-P`. Use `systemd.services.bluetooth.serviceConfig.ExecStart` override instead.

### journalctl warnings are not "expected"

Every warning and error in `journalctl -b 0 -p warning` is worth investigating. Do not dismiss as "harmless" — present findings and let the user decide.

## Root-Level Files

Undocumented files that live in the repo root:

### Tooling / Formatting

| File | Purpose |
|------|---------|
| `treefmt.nix` | treefmt config as Nix (used by `parts/formatting.nix` via treefmt-nix flake). Formatters: alejandra, deadnix, dockfmt, just, prettier, rustfmt, shfmt, statix, toml-sort, yamlfmt, trailing-whitespace-fixer. Excludes `secrets/*`, `*.age`, `*.toml` (global). |
| `treefmt.toml` | TOML mirror of the same treefmt config (used when running `treefmt` directly outside Nix). Must be kept in sync with `treefmt.nix`. |
| `statix.toml` | statix linter config — disables `empty_pattern`, `manual_inherit`, `manual_inherit_from`; pins `nix_version = 2.31.2`; ignores `.direnv/`, `result*/`, `secrets/`, `.git/`. |
| `namaka.toml` | [namaka](https://github.com/nix-community/namaka) snapshot test config. Tests discovered from `tests/` subdirs (each with `expr.nix` + optional `format.nix`). Currently disabled in pre-commit. |
| `.yamllint` | yamllint config — extends `default`, disables `document-start` rule. |
| `devshell.nix` | Legacy `pkgs.mkShell` dev shell (predates `parts/devshells.nix`). Contains all dev tools (age, alejandra, gitleaks, just, nh, pre-commit, sops, statix, etc.). Used when entering the repo with `nix-shell` instead of `nix develop`. |

### Secrets Scanning / Pre-commit

| File | Purpose |
|------|---------|
| `.pre-commit-config.yaml` | Pre-commit hooks: yamlfmt, ripsecrets, gitleaks, taplo, alejandra, deadnix, statix, dangerous-shell-patterns, pre-commit-hook-ensure-sops. namaka hook disabled. |
| `.gitleaks.toml` | gitleaks config — extends default ruleset; allowlists: SOPS `ENC[AES256_GCM...]` values, age public keys, age encrypted file blocks, all of `secrets/`, false-positive patterns (`--user=admin`, NextDNS URLs), `config.sops.secrets.*.path` references in Nix. |
| `.gitleaks-baseline.json` | gitleaks baseline of known/accepted findings — prevents re-alerting on pre-existing suppressions. |
| `.ripsecrets.toml` | ripsecrets config — suppresses known false-positive secret patterns (SSH key prefixes, GPG key ID, stale API keys from old configs). Also allowlists specific files via `[allowlist].paths`. |

### Secrets / SOPS Config

| File | Purpose |
|------|---------|
| `.sops.yaml` | SOPS creation rules. All files matching `secrets/.*` are encrypted with 4 age keys: homeserver, desktop, matebook, gcp-relay. |
| `.sopsrc` | sops client config — points to `.sops.yaml`, sets `decryptionOrder = ["age"]`, `encryptionOrder = ["age"]`. |

### MCP / AI

| File | Purpose |
|------|---------|
| `.mcp.json` | Claude Code MCP server definitions for this project. Servers: fetch, filesystem (`/etc/nixos`, `/home/zeev/src`), kubernetes (mcp-k8s-go), mcp-nixos, memory, python (uvx), sequential-thinking, tavily (stdio); github, fizzy, supabase (HTTP). Pinned to `/nix/store/...` paths for stdio — regenerated by the `modules/TUI/ai-tools/mcp` HM activation script. |
| `CLAUDE.md` | Project-level instructions for Claude Code. Contains MCP routing table, project layout, key conventions, and critical rules (no sudo, no nix build, no sops encrypt). |

### Git Config

| File | Purpose |
|------|---------|
| `.gitignore` | Ignores: `result`, `core*`, `.vscode`, `.idea`, `.claude/*` (except `memory/`, `CLAUDE.md`, `settings.json`), `.mcp.json`, `.direnv`, decrypted secret patterns (`*.decrypted.*`, `*.sopsbak`). |
| `.gitattributes` | (Empty — no custom attributes configured.) |

### Justfile

`justfile` contains task shortcuts (run with `just <recipe>`). **Note:** most recipes reference stale targets (e.g., `darwinConfigurations.macbook`, `nixfmt`, `nixos-rebuild-ng`, `rsync` to `/etc/nixos/`) and are largely outdated. Active/useful recipes:

| Recipe | What it does |
|--------|-------------|
| `deploy-gcp` | `nixos-rebuild switch` to gcp-relay via SSH |
| `deploy-homeserver` | Runs `./deploy.sh homeserver` |
| `check` / `test` | `nix flake check` |
| `deploy-desktop` | Runs `./deploy.sh desktop` |
| `dry-run $host` | `nixos-rebuild-ng dry-activate` on remote host |
| `fmt` | `nixfmt **/*.nix` (uses nixfmt, not alejandra — prefer `nix fmt` instead) |

### tools/scripts

Pre-commit and CI helper scripts in `tools/scripts/`:

| Script | Trigger | Purpose |
|--------|---------|---------|
| `check-dangerous-patterns.sh` | pre-commit (`dangerous-shell-patterns` hook), `.nix` + `.sh` files | Blocks `exec zellij/tmux/screen/wezterm` in shell configs — causes lockouts if zsh init runs `exec` unconditionally |
| `check-installer-keys.sh` | (manual) | Validates `hosts/installer/authorized_keys`: ensures file exists, fixes permissions to 600, validates each line is a valid SSH public key via `ssh-keygen -lf` |

### Desktop Hardware Notes

| File | Purpose |
|------|---------|
| [`docs/efi.md`](efi.md) | Reference guide for MSI MAG B650 TOMAHAWK WIFI hidden UEFI settings. Documents `AmdSetupRPL` VarStore offsets (CPU, memory, power, prefetchers, NBIO/security, GFX) with `setup_var.efi` recipes. For BIOS tuning / unlocking suppressed settings. Desktop-specific. |
| [`docs/bios-desktop-settings.md`](bios-desktop-settings.md) | Standard BIOS setup-screen checklist for the same board (EXPO, boot mode, virtualization/Secure Boot, TPM, fan curves) — for recovering settings after a firmware update wipes NVRAM. Desktop-specific. |
| `cpu_flags.sh` | One-shot script: fetches `cpufeatures.h` from kernel.org, cross-references `/proc/cpuinfo` flags with their human-readable descriptions. |

### Other

| File | Purpose |
|------|---------|
| `jellycli.yaml` | Empty file — jellycli config placeholder. |

## Formatting

`nix fmt` runs **treefmt** (via `parts/formatting.nix` + `treefmt.nix`) with: alejandra (Nix), deadnix, statix, prettier (JSON/YAML/MD/HTML/JS), shfmt (shell), yamlfmt, toml-sort, dockfmt, rustfmt, trailing-whitespace-fixer.

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

`infra/tf/gcp-relay/` manages GCP infrastructure state for the `gcp-relay` host:

- **GCP resources**: static external IP (`google_compute_address`), GCS bucket for NixOS images, compute instance import
- Remote state backend: GCS bucket (`gcp-relay-nixos-images`, prefix `tofu/state`)
- Variables: `project` (homelab-497717), `region` (us-central1), `zone` (us-central1-a), `image_date` (YYYYMMDD)
- Secrets injected via env vars; never committed

Run: `cd infra/tf/gcp-relay && tofu init && tofu apply -var="image_date=YYYYMMDD"`
