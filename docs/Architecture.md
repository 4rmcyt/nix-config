# Architecture

## Overview

NixOS flake for 4 hosts managed as a single repository. Built on **flake-parts** with **import-tree** for automatic module discovery. All hosts share a common base layer; host-specific config lives in `parts/hosts/<name>/`.

## Flake Structure

```
flake.nix                   # Entry point — delegates to flake-parts + import-tree ./parts
infra/tf/gcp-relay/         # Terraform/OpenTofu — GCP infrastructure for gcp-relay (static IP, GCS bucket, VM instance)
parts/                      # Auto-imported flake-parts modules
  configurations/nixos.nix  # Defines configurations.nixos option → nixosConfigurations
  hosts/<name>/             # Per-host configuration (flake-parts module)
  shared-nixos-settings.nix # modules.nixos.base — shared nix daemon / caches / sops / access-token wiring
  home-manager-integration.nix # modules.nixos.base — imports sops-nix, disko, nix-topology NixOS modules
  hm.nix                    # modules.nixos.hm — Home Manager NixOS module + HM base wiring (opt-in per host)
  home-manager-base.nix     # modules.homeManager.base — sops, nixvim, overlays, stateVersion
  workstation.nix          # modules.nixos.workstation — facter + ucodenix + gnupg (desktop/laptop/server);
                           # modules.nixos.workstationGui — GUI/{chrome,flatpak,kdeconnect,nemo} + nfs-client (desktop/matebook);
                           # modules.homeManager.workstation — GUI/TUI HM apps (desktop/matebook)
  shared-programs.nix       # modules.nixos.base — common programs on all hosts (zsh, nh)
  meta.nix                  # options.meta (stateVersion, owner)
  owner.nix                 # meta.owner — sourced from the private `private` flake input (identity + LAN topology)
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
  base/                     # Shared base: logging, msmtp
  options/                  # Custom options: my.defaults.*, my.network.*
  database/                 # postgresql, redis, couchdb
  monitoring/               # Split by concern: grafana.nix, loki.nix, prometheus.nix,
                            #   alertmanager.nix, alloy-server.nix, geoip.nix (default.nix
                            #   just imports them); plus client-side alloy-client.nix and
                            #   node-exporter-client.nix (imported directly by non-homeserver hosts)
  networking/               # ssh, tailscale, traefik, headscale, cloudflared,
                            #   caddy, dnssec, nfs, nut-client/server, wireguard
  security/                 # crowdsec, fail2ban, kanidm
  services/                 # Application services: home-assistant, radicale, homepage, miniflux,
                            #   nixarr, atuin-server, dispatcharr, microbin, komf, komga, ntfy,
                            #   k3s + argocd (homeserver; see Infrastructure.md)
  containers/               # Podman container support
  disko/                    # Declarative disk layouts per host
  users/                    # Per-user NixOS config (zeev)
  backup/                   # Backup tooling
  dots/                     # Dotfile management
  WM/                       # Window manager HM modules
    default.nix             # XDG user dirs (HM level)
    gtk.nix                 # GTK theming
    mime/                   # MIME type associations
    mango/                  # mango WM (desktop): settings, keybinds, startup, windowrules, nvidia, monitors
    niri/                   # niri WM (matebook): settings, keybinds, startup, windowrules, nvidia, monitors
  GUI/                      # GUI apps: firefox, chrome, chromium, obsidian, mpv, IDE (vscode, zed),
                            #   terminal, discord, easyeffects, nemo, coolercontrol, kdeconnect,
                            #   virt-manager, waydroid, flatpak, jellyfin-mpv-shim, bb-launcher
                            #   (thunderbird module removed — personal account config lives in inputs.private)
  TUI/                      # Terminal tools: zsh, zellij, atuin, starship, tmux, tty, neovim,
                            #   ai-tools (claude-code, antigravity-cli, mcp, llama-cpp)
                            #   ai-tools sub-dirs: agents/, skills/, commands/, system-prompt/
  dev/                      # Developer tools
  nix/                      # Nix daemon config (lix)
```

## Options System

Global options live in `modules/options/`. Never hardcode values — reference via `config.my.*`.

Identity (email, GPG key, full name, domain) and the full LAN topology (host IPs,
MAC addresses, infrastructure/smart-home/mobile device addresses, GCP relay IP,
NextDNS profile id) are **not in this repo**. They live in a separate private
flake, wired as `inputs.private` (`git+ssh://…/nix-config-private`), and surface
through `my.defaults.*` / `my.network.*` option defaults (plus `meta.owner.username`
in the flake-parts scope). sops can't hold them — they're needed at eval time,
before sops-nix decrypts.
`modules/options/private-example.nix` documents the expected schema. The personal
Thunderbird account config also lives there (`inputs.private.homeModules.thunderbird`).

| Option namespace     | File                          | Purpose                                      |
|----------------------|-------------------------------|----------------------------------------------|
| `my.defaults.*`      | `options/defaults.nix`        | user, email, git identity, domain, timezone, locale, GCP relay IP, NextDNS profile id (from `inputs.private`) |
| `my.network.*`       | `options/network.nix`         | gateway, subnets, service ports (`ports.<name>` int + derived read-only `portScope.<name>` = internet/lan/localhost) — local defaults; host addresses/MACs/infrastructure/DHCP reservations sourced from `inputs.private` |
| `my.traefik.*`       | `networking/traefik/`         | Traefik reverse proxy                        |
| `my.headscale.*`     | `networking/headscale/`       | Headscale coordination server                |
| `my.nodeExporter.*`  | `monitoring/node-exporter-client.nix` | Per-host Prometheus node exporter   |
| `my.unbound.*`       | `networking/unbound/`         | Unbound DNS resolver                         |
| `my.crowdsec.*`      | `security/crowdsec/`          | CrowdSec IDS + bouncer                       |
| `my.hardening.*`     | `security/hardening.nix`      | System hardening (SSH, kernel, systemd defaults) |

## Host Wiring

Each `parts/hosts/<name>/configuration.nix` declares a `configurations.nixos.<name>.module`:

```nix
configurations.nixos.homeserver.module = {...}: {
  imports = [
    nixosBase           # modules.nixos.base — shared-nixos-settings + HM integration + shared-programs
    nixosHm             # modules.nixos.hm  — Home Manager (skipped on gcp-relay)
    nixosWorkstation    # modules.nixos.workstation — facter/ucodenix/gnupg (skipped on gcp-relay)
    ../../../hosts/nixos/homeserver
    inputs.nixarr.nixosModules.default
    ../../../modules/nix/lix
  ];
  home-manager.users.zeev.imports = [ ../../../home/homeserver ];
};
```

`configurations/nixos.nix` maps each entry to `lib.nixosSystem`. **gcp-relay** is
headless — it imports only `nixosBase`, no HM, no workstation modules.
**desktop** and **matebook** additionally import `nixosWorkstationGui`
(`modules.nixos.workstationGui`) and `hmWorkstation`.

### Host → Nix daemon variant

| Host        | Nix daemon        |
|-------------|-------------------|
| desktop     | `modules/nix/lix` |
| homeserver  | `modules/nix/lix` |
| matebook    | `modules/nix/lix` |
| gcp-relay   | base default (stock nixpkgs `nix`) |

## Secrets

All secrets managed by **sops-nix** with age encryption.

- Keys: `/root/.config/sops/age/keys.txt` (NixOS), `~/.config/sops/age/keys.txt` (HM)
- Reference pattern: `config.sops.secrets.<name>.path`
- Secret files: `secrets/*.yaml`, `secrets/*.env`, `secrets/*.json`, `secrets/*.bin`
- Never commit plaintext; never call `sops encrypt` via tooling — give the user the command

## Nix Implementation

**Lix** replaces the stock nix daemon on desktop, homeserver and matebook (`modules/nix/lix`). gcp-relay runs stock nixpkgs `nix`. Channels disabled. Registry pinned to `inputs.nixpkgs`. IFD enabled (`allow-import-from-derivation = true`).

All hosts get:
- `nix-auth` — `nix auth` subcommand for token management
- `nixos-needsreboot` — checks if a rebuild requires a reboot; runs as activation script

Binary caches (from `parts/shared-nixos-settings.nix`, priority order):
1. `arr-packages.cachix.org` (priority 0)
2. `nix-community.cachix.org`, `cache.nixos.org`, `cache.flox.dev`, `llama-cpp.cachix.org` (priority 1)
3. `noctalia.cachix.org` (2), `devenv.cachix.org` (3), `nixpkgs-unfree.cachix.org` (5)
4. Per-host push cache added in `parts/hosts/<host>/configuration.nix`: `4rmcyt-<host>.cachix.org`
5. desktop additionally: `cache.nixos-cuda.org`, `cuda-maintainers.cachix.org`, `4rmcyt-gcp.cachix.org`

GitHub access token loaded via sops secret `nix_access_token`, written to `/run/nix-access-tokens.conf` by a oneshot systemd service at boot. `NIX_USER_CONF_FILES` points to this file for both the nix daemon and user sessions.

## Package Overlays

No local `overlays/` directory. All overlays come from flake inputs:

- **HM scope** (`parts/home-manager-base.nix`): `mcp-servers-nix`, `nur`, `nix-vscode-extensions`, `noctalia`
- **homeserver NixOS scope** (inline in `parts/hosts/homeserver/configuration.nix`): `homepage-dashboard` pinned to v1.13.1, and `sonarr`/`radarr`/`prowlarr`/`bazarr`/`jellyfin`/`jellyfin-web` taken from `inputs.arr-packages`

## Desktop WM Stack

**Desktop uses mango; matebook uses niri.** Both pair with **noctalia** v5 (native C++ binary, no Quickshell) as bar/shell. Desktop ran Hyprland until 2026-08-22, when it was fully replaced by mango; the Hyprland modules have since been removed.

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

**mango wiring:** desktop uses **nixpkgs' own `programs.mango`** module (portal + systemPackages wiring), with `programs.mango.package` and greetd's exec both pointed at `inputs.mango.packages.<system>.mango` (`github:mangowm/mango/wl-only`). `inputs.mango.nixosModules.mango` is deliberately **not** imported — it re-declares `programs.mango.enable` and conflicts with the nixpkgs module. `inputs.mango.hmModules.mango` (`wayland.windowManager.mango`) is imported on the HM side.

**greetd** on desktop execs `env WLR_RENDERER=vulkan …/bin/mango` directly (no UWSM — mango's own HM module binds a `mango-session.target` to `graphical-session.target` itself). `WLR_RENDERER=vulkan` must be on the exec, not in `config.conf` — wlroots picks its renderer before mango reads the config file.

**HDR on desktop's mango build:** requires tracking the **`wl-only` branch**, not `main` (corrected again 2026-08-23 — a same-day earlier edit wrongly claimed no special branch was needed; that was wrong, see `flake.nix`'s comment on the `mango` input for the full trail, including why the `hdr` branch was rejected too). `main`'s `meson.build` unconditionally requires `libscenefx` and links it into the `mango` executable; scenefx doesn't support the vulkan renderer HDR needs, so `drw->features.output_color_transform` (checked in `src/ext-protocol/hdr.h`'s `output_supports_hdr()`) never comes back true on `main` no matter what config is set — confirmed both by mango's own docs (`docs/configuration/monitors.md`: "HDR is only supported in wl-only branch, since it requires the vulkan renderer but scenefx is not supported yet") and by diffing `meson.build` between branches. `wl-only` drops the `scenefx` `dependency()` call and its executable-link entirely, and its wlroots pin (`wlroots-0.20`) matches `main`'s and `nix/default.nix`'s, so — unlike the `hdr` branch — it isn't known-broken on the packaging side. `hdr:1` alone was not enough for the two ASUS VG289Q panels — their EDID apparently doesn't clear wlroots' `supported_primaries`/`supported_transfer_functions` bar `output_supports_hdr()` checks against, so `hdr_force:1` (see `modules/WM/mango/monitors/desktop.nix`) is required to skip those two EDID checks. `WLR_RENDERER=vulkan` is still required regardless of `hdr_force` — it's the separate, non-skippable `output_color_transform` check. Niri has no HDR path at all (see below); Hyprland ≥0.55 was the only WM in this config with a working HDR10 output path (`wp_color_management v2`) before the switch.

### niri (matebook only)

| File | Purpose |
|------|---------|
| `modules/WM/niri/default.nix` | niri settings, session vars, input/layout |
| `modules/WM/niri/noctalia.nix` | noctalia HM config |
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

**noctalia inputs:**
- `inputs.noctalia` = `github:noctalia-dev/noctalia/cachix` (v5, C++ rewrite — pinned to the `cachix` branch, which always points at the latest commit noctalia's own CI has finished pushing to `noctalia.cachix.org`, so it never forces a local compile the way tracking `main` directly can)
- Migrated from `legacy-v4` (QML/Quickshell, archived upstream) on 2026-08-23. No settings migration from v4 — separate config format (TOML, `[theme.templates.user.*]` instead of `programs.noctalia-shell.user-templates`). IPC CLI changed from `noctalia-shell ipc call <target> <action>` to `noctalia msg <command> [args...]`; command names changed too (e.g. `launcher toggle` → `panel-toggle launcher`, `darkMode toggle` → `theme-mode-toggle`). No v5 equivalent exists for the old standalone color-picker toggle bind (dropped from mango/niri binds).
- Package renamed `noctalia-shell` → `noctalia`; overlay attr is `pkgs.noctalia`.
- No more `noctalia-qs` or `inputs.quickshell` inputs — v5 has no Quickshell dependency at all (removed from flake.nix).
- Exports: `homeModules.default`, `nixosModules.default`, `overlays.default`
- NixOS import: `inputs.noctalia.nixosModules.default` on desktop + matebook
- HM import: `inputs.noctalia.homeModules.default` on desktop + matebook
**Theming:** noctalia drives colors. Stylix was removed 2026-09-05 (flake input + `modules/GUI/stylix/` deleted — it had been wired but never enabled on any host).

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
| `.ripsecrets.toml` | ripsecrets config — suppresses known false-positive secret patterns (SSH key prefixes, GPG key ID, stale API keys from old configs). Also allowlists specific files via `[allowlist].paths`. |

### Secrets / SOPS Config

| File | Purpose |
|------|---------|
| `.sops.yaml` | SOPS creation rules. All files matching `secrets/.*` are encrypted with 4 age keys: homeserver, desktop, matebook, gcp-relay. |
| `.sopsrc` | sops client config — points to `.sops.yaml`, sets `decryptionOrder = ["age"]`, `encryptionOrder = ["age"]`. |

### MCP / AI

| File | Purpose |
|------|---------|
| `.mcp.json` | Symlink → `~/.config/mcp/mcp.json` (generated by the `modules/TUI/ai-tools/mcp` HM module). Servers: fetch, filesystem, kubernetes, mcp-nixos, memory, python, sequential-thinking, tavily, opentofu (stdio); github, fizzy, supabase (HTTP). |
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
| `deploy-gcp` | `nixos-rebuild switch --flake .#gcp-relay --target-host zeev@gcp-relay --build-host localhost --elevate=sudo`, then `cachix push 4rmcyt-gcp`, then `nh clean all` |
| `deploy-homeserver` / `deploy-matebook` | `nixos-rebuild switch --flake .#<host> --target-host zeev@<host> --build-host localhost --elevate=sudo` |
| `deploy-desktop` | Runs `./deploy.sh desktop` |
| `check` / `test` | `nix flake check` |
| `fmt` | `nix fmt` |
| `push-caches` | `cachix push 4rmcyt-$(hostname) /run/current-system` |
| `dry-run $host` / `deploy $host` / `copy $host` | `nixos-rebuild-ng` + `rsync` to `/etc/nixos` — older workflow, mostly unused |

Stale recipes still in the file: `update` (references non-existent `darwinConfigurations.macbook`), `build-iso`.

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

Remote hosts are deployed manually via `nixos-rebuild` over SSH — recipes live in the [`justfile`](../justfile). Build happens on the local machine (`--build-host localhost`), activation on the target with `--elevate=sudo`. No deploy-rs.

| Host       | Recipe / method |
|------------|-----------------|
| homeserver | `just deploy-homeserver` → `nixos-rebuild switch --flake .#homeserver --target-host zeev@homeserver --build-host localhost --elevate=sudo` |
| matebook   | `just deploy-matebook` (same shape, `zeev@matebook`) |
| gcp-relay  | `just deploy-gcp` → deploy `.#gcp-relay`, then push closure to `4rmcyt-gcp` Cachix, then `nh clean all` |
| desktop    | Local: `nixos-rebuild switch --flake .#desktop` / `nh os switch` |

Updates are manual everywhere — no auto-upgrade timer.

**ZFS/mount safety:** prefer `nixos-rebuild boot` + reboot over `switch` when config changes affect active mount units. See [Infrastructure.md](Infrastructure.md) ZFS Safety Rules.

## Topology Diagram

`just topology` (or `nix build .#topology.x86_64-linux.config.output`) generates two SVGs via **nix-topology** — physical `main.svg` and `network.svg` — written to `docs/topology.svg` / `docs/topology-network.svg` and embedded in the README. Interface `addresses` in the annotations are descriptive labels, not real IPs, so the committed SVGs expose nothing beyond `docs/Infrastructure.md`.

- **`parts/topology.nix`** — flakeModule wiring + the global topology: `internet`, `isp-router`, the hand-described `router` appliance node (the NixOS host was removed), `switch-office`, `switch-livingroom`, `ap-trusted`, `ap-iot`, and the `trusted` / `iot` / `media` / `work` / `tailnet` network CIDRs. Four hosts are included (desktop, homeserver, matebook, gcp-relay).
- **`modules/topology/default.nix`** — NixOS module imported into `modules.nixos.base` (every host). Per-host `topology.self`: interfaces, network membership, hardware blurbs, a shared `tailscale0` overlay interface. Also forces `services.traefik.details = {}` on homeserver so the diagram does **not** enumerate every Traefik router and backend URL (job-kombayn included).
- 802.1Q is not representable in nix-topology — the office switch is drawn as the trusted segment it mostly carries; the IoT AP hangs off the router's `vlan20` interface.
- `matebook` currently exists only in config, not yet deployed — noted in its `hardware.info`.

## Terraform / OpenTofu

`infra/tf/gcp-relay/` manages GCP infrastructure state for the `gcp-relay` host:

- **GCP resources**: static external IP (`google_compute_address`), GCS bucket for NixOS images, compute instance import
- Remote state backend: GCS bucket (`gcp-relay-nixos-images`, prefix `tofu/state`)
- Variables: `project` (homelab-497717), `region` (us-central1), `zone` (us-central1-a), `image_date` (YYYYMMDD)
- Secrets injected via env vars; never committed

Run: `cd infra/tf/gcp-relay && tofu init && tofu apply -var="image_date=YYYYMMDD"`
