# Architecture

## Overview

NixOS flake for 4 hosts managed as a single repository. Built on **flake-parts** with **import-tree** for automatic module discovery. All hosts share a common base layer; host-specific config lives in `parts/hosts/<name>/`.

## Architectural Invariants

Deliberate decisions that recurring "improvements" tend to undo. Changing any of these is a real architectural change — do it consciously, not by drift.

- **This document is canonical.** `CLAUDE.md`, `README.md`, and workflow comments point here for architecture detail; they must not re-describe it. Update this file in the same change that alters the structure.
- **`parts/` is auto-imported; `modules/` is not.** Every `.nix` under `parts/` is loaded via `import-tree ./parts`. Everything under `modules/` is imported *explicitly* from a host config (or a `parts/` deferred module) — so "the module exists" and "the module is active on this host" stay distinct facts, visible in one place per host.
- **`parts/foo.nix` may depend on a declared option, never on a sibling file existing.** Deferred modules (`modules.nixos.*`, `configurations.nixos.*`) are the contract between `parts/` files. No `parts/` file may assume load order or the presence of another `parts/` file.
- **Hosts are discovered from `parts/hosts/*/`.** One directory per host, 1:1 with `configurations.nixos.<name>`. CI's build matrix is derived from this (see [CI-CD.md](CI-CD.md)); adding a host must not require editing a workflow.
- **`treefmt.nix` is the sole formatter config.** No standalone `treefmt.toml`. Formatting runs through `nix fmt`.
- **Dev shells are defined inline in `parts/devshells.nix`.** No root-level `devshell.nix` / `shell.nix`.
- **Identity and LAN topology come only from `inputs.private`.** Surfaced as `my.defaults.*` / `my.network.*` (NixOS scope) and `meta.owner.*` (flake-parts scope). Never hardcoded in the public tree; schema in [`modules/options/private-example.nix`](../modules/options/private-example.nix).
- **`nix flake check` is a blocking CI gate; `nix fmt` is advisory.** A flake-check failure stops the build; a formatting failure only warns.

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
  home-manager-base.nix     # modules.homeManager.base — sops, nixvim, overlays (shared + HM-only), stateVersion
  workstation.nix          # modules.nixos.bareMetal — facter + ucodenix + gnupg + nix dev tools
                           #   (every physical host: desktop/matebook/homeserver; NOT the gcp-relay VM);
                           # modules.nixos.workstationGui — GUI/{browsers/chrome,flatpak,kdeconnect,nemo} + nfs-client (desktop/matebook);
                           # modules.homeManager.workstation — GUI/TUI HM apps (desktop/matebook)
  shared-programs.nix       # modules.nixos.base — common programs on all hosts (zsh, nh)
  nix-mineral.nix           # modules.nixos.nixMineral — inputs.nix-mineral's NixOS module (desktop/gcp-relay/homeserver; not matebook)
  meta.nix                  # options.meta (stateVersion, owner)
  owner.nix                 # meta.owner — sourced from the private `private` flake input (identity + LAN topology)
  schemas.nix               # flake.schemas — flake-schemas + custom topology schema
  topology.nix              # nix-topology SVG diagram generation
  formatting.nix            # treefmt (alejandra, deadnix, statix, shfmt, yamlfmt)
  devshells.nix             # Dev shells (inline): default (dev tooling: age, sops, just, nh, pre-commit, …), ide
hosts/nixos/<name>/         # NixOS system config + hardware-configuration.nix
home/<name>/                # Home Manager config per host
modules/                    # NixOS/HM modules (NOT auto-imported; referenced by host configs)
lib/                        # Plain helpers imported by path: overlays.nix, overlays-hm.nix, cachix.nix, cloudflare-acme-secret.nix, caddy-with-plugins.nix
secrets/                    # sops-encrypted YAML/binary files
tools/                      # Helper scripts and tooling
```

## Module Layer

Modules are **not** auto-imported. They are referenced explicitly from host configs.

```
modules/
  base/                     # Shared base: logging, msmtp, scx-hardening (sandbox for services.scx when enabled)
  options/                  # Custom options: my.defaults.*, my.network.*
  database/                 # postgresql, redis, couchdb
  monitoring/               # One folder per component, each a default.nix plus its data:
                            #   grafana/ (+ dashboards/), prometheus/ (+ alerts.yaml),
                            #   victorialogs/ (+ vmalert, rules.nix), alertmanager/, geoip/ —
                            #   homeserver stack, imported by monitoring/default.nix.
                            #   journal-upload/ and node-exporter/ are per-host clients,
                            #   imported directly by each host (homeserver gets journal-upload
                            #   via monitoring/default.nix)
  networking/               # ssh, tailscale, headscale, cloudflared,
                            #   caddy, caddy-homeserver, dnssec, nfs, nut-client/server, wireguard,
                            #   lan-routing (desktop: keeps trusted LAN off the Tailscale subnet route)
  security/                 # crowdsec, kanidm
  services/                 # Application services: home-assistant, radicale, homepage, miniflux,
                            #   nixarr, atuin-server, microbin, komf, komga, ntfy,
                            #   k3s + argocd (homeserver; see Infrastructure.md)
  containers/               # Podman support; containers on the bridge (only home-assistant uses --network=host), ports published on 127.0.0.1/LAN IP, host deps via host.containers.internal + per-port podman0 firewall; all but home-assistant run --userns=auto (subuid range for user `containers`) with :idmap volumes
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
  GUI/                      # GUI apps: browsers/ (gecko-common, firefox, zen, chrome, chromium), obsidian, mpv, IDE (vscode, zed),
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
| `my.network.*`       | `options/network.nix`         | subnets, service ports (`ports.<name>` int + derived read-only `portScope.<name>` = internet/lan/localhost) — local defaults; gateway, host addresses/MACs/infrastructure/DHCP reservations sourced from `inputs.private` |
| `my.caddyHomeserver.*` | `networking/caddy-homeserver/` | Caddy reverse proxy for homeserver |
| `my.uaExit.*`         | `networking/ua-exit/`         | Second tailscaled as `ua-exit` exit node inside a Ukraine WireGuard netns |
| `my.uaExitOvpn.*`     | `networking/ua-exit-ovpn/`    | Third tailscaled as `ua-exit-ovpn` exit node inside a hand-made Ukraine OpenVPN netns |
| `my.headscale.*`     | `networking/headscale/`       | Headscale coordination server                |
| `my.nodeExporter.*`  | `monitoring/node-exporter/` | Per-host Prometheus node exporter   |
| `my.unbound.*`       | `networking/unbound/`         | Unbound DNS resolver                         |
| `my.crowdsec.*`      | `security/crowdsec/`          | CrowdSec IDS + bouncer                       |

## Host Wiring

Each `parts/hosts/<name>/configuration.nix` declares a `configurations.nixos.<name>.module`:

```nix
configurations.nixos.homeserver.module = {...}: {
  imports = [
    nixosBase           # modules.nixos.base — shared-nixos-settings + HM integration + shared-programs
    nixosHm             # modules.nixos.hm  — Home Manager (skipped on gcp-relay)
    nixosBareMetal      # modules.nixos.bareMetal — facter/ucodenix/gnupg/dev tools (skipped on gcp-relay)
    ../../../hosts/nixos/homeserver
    inputs.nixarr.nixosModules.default
    ../../../modules/nix/lix
  ];
  home-manager.users.zeev.imports = [ ../../../home/homeserver ];
};
```

`configurations/nixos.nix` maps each entry to `lib.nixosSystem`. **gcp-relay** is
headless — it imports only `nixosBase`, no HM, no bare-metal modules.
**desktop** and **matebook** additionally import `nixosWorkstationGui`
(`modules.nixos.workstationGui`) and `hmWorkstation`.

`hmWorkstation` includes [`modules/GUI/browsers/zen`](../modules/GUI/browsers/zen/default.nix),
which imports `inputs.zen-browser.homeModules.beta` (`0xc000022070/zen-browser-flake`).
Firefox and Zen both pull engine-level prefs (media/gfx/network/security/telemetry/AI),
`policies` (addons, uBlock) and search engines from
[`modules/GUI/browsers/gecko-common`](../modules/GUI/browsers/gecko-common/default.nix)
(plain attrsets, `import`ed with `{lib}`). Firefox-only UI/session/scroll prefs and the
locked toolbar layout stay in `browsers/firefox/`; Zen keeps its own defaults for those
(sessionstore interval, resetPBM, smooth scroll) plus `zen.*` prefs. Firefox stays the default browser.

**desktop**, **gcp-relay**, and **homeserver** additionally import
`nixosNixMineral` (`modules.nixos.nixMineral`, defined in
[`parts/nix-mineral.nix`](../parts/nix-mineral.nix)) — settings in
[`hosts/nixos/desktop/hardening.nix`](../hosts/nixos/desktop/hardening.nix) /
[`hosts/nixos/gcp-relay/hardening.nix`](../hosts/nixos/gcp-relay/hardening.nix) /
[`hosts/nixos/homeserver/hardening.nix`](../hosts/nixos/homeserver/hardening.nix).
Alpha software (`cynicsketch/nix-mineral`), tracks the `main` branch (no tag
pin in `flake.nix`). `modules.nixos.nixMineral` only wires in the module
itself — not merged into `modules.nixos.base` — since each host needs
different filesystem/network overrides (ZFS vs Btrfs vs single-partition,
exit-node routing); matebook is not planned.

`modules/security/hardening.nix` (the old hand-rolled `my.hardening.*`
module: SSH ciphers, sysctl, per-service systemd hardening) is **deleted**.
Replaced per-host by nix-mineral (sysctl, SSH via
`nix-mineral.extras.misc.ssh-hardening`) plus systemd-hardening moved
directly into the services it targeted, since nix-mineral doesn't do
per-service systemd hardening at all (out of scope upstream):
`systemd.services.crowdsec.serviceConfig` in
[`modules/security/crowdsec/default.nix`](../modules/security/crowdsec/default.nix),
`systemd.services.prometheus.serviceConfig` in
[`modules/monitoring/prometheus/`](../modules/monitoring/prometheus/default.nix),
`systemd.services.caddy.serviceConfig` in
[`modules/networking/caddy/default.nix`](../modules/networking/caddy/default.nix).
The old module's `my.hardening.serviceBase` constant (used by
`modules/database/couchdb` and `modules/database/redis`) was inlined at
both call sites instead of kept as a shared option.

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
5. desktop additionally: `cache.nixos-cuda.org` (CUDA cache; migrated from `cuda-maintainers.cachix.org`, which no longer serves `nix-cache-info`), `4rmcyt-gcp.cachix.org`

GitHub access token loaded via sops secret `nix_access_token`, written to `/run/nix-access-tokens.conf` by a oneshot systemd service at boot. `NIX_USER_CONF_FILES` points to this file for both the nix daemon and user sessions.

## Package Overlays

- **Shared (HM + system)** — [`lib/overlays.nix`](lib/overlays.nix): generic upstream-bug workarounds, not tied to any one host. Currently: `cudaPackages.buildRedist` `__structuredAttrs = false` (nixpkgs#323126/#422989 — multi-output fixup crashes) and `intel-compute-runtime-legacy1` `-Wno-error=sfinae-incomplete` (gcc-16 stricter diagnostics, no upstream patch). `import`ed by `parts/home-manager-base.nix` and by `modules.nixos.base` in `parts/shared-nixos-settings.nix` (so every NixOS host gets it at system level).
- **HM-only scope** — [`lib/overlays-hm.nix`](lib/overlays-hm.nix) (`import`ed by `parts/home-manager-base.nix` alongside the shared list): `mcp-servers-nix`, `nur`, `nix-vscode-extensions`, `noctalia`, plus a small local overlay that restores `mcp-server-{memory,filesystem,sequential-thinking}` from vanilla nixpkgs (mcp-servers-nix's TS builds of those are broken from source; it's kept only for `tavily-mcp`).
- **Host-specific system scope** — set in the one host or module that needs it; NixOS merges these lists with the shared one from `modules.nixos.base`:
  - `parts/hosts/homeserver/configuration.nix` — `sonarr`/`radarr`/`prowlarr`/`bazarr`/`jellyfin`/`jellyfin-web` from `inputs.arr-packages`
  - `parts/hosts/gcp-relay/configuration.nix` — `inputs.headscale.overlays.default`
  - `hosts/nixos/desktop/hardware-configuration.nix` — `linux-firmware` MT7922 Wi-Fi blob rollback (hardware-specific)
  - `modules/services/microbin/default.nix` — `microbin` theming/asset override (coupled to the module)
- **Targeted package pins (no overlay)** — `programs.ssh.package` in `modules.nixos.base` (`parts/shared-nixos-settings.nix`) is `openssh` 10.6p1 via `overrideAttrs`; `services.openssh.package` defaults to it, so client + sshd are pinned on every host without rebuilding openssh's reverse deps. Temporary until nixpkgs#570987 reaches `nixos-unstable`.

## Desktop WM Stack

**Desktop uses mango; matebook uses niri.** Both pair with **noctalia** v5 (native C++ binary, no Quickshell) as bar/shell. Desktop ran Hyprland until 2026-08-22, when it was fully replaced by mango; the Hyprland modules have since been removed.

### mango (desktop only)

| File | Purpose |
|------|---------|
| `modules/WM/mango/default.nix` | mango settings (structured Nix → `config.conf`), session vars, qt theming, scroller layout, blur/shadow effects |
| `modules/WM/mango/noctalia.nix` | noctalia HM config |
| `modules/WM/mango/binds.nix` | keybindings (`bind`/`mousebind` in mango's own comma-separated grammar) |
| `modules/WM/mango/startup.nix` | own `autostart.sh` via `xdg.configFile` + `exec_once` (upstream `autostart_sh` emits `exec-once`): cliphist, wl-clip-persist, noctalia, materialgram, vesktop, coolercontrol |
| `modules/WM/mango/windowrules.nix` | floating rules (`window_rule=` strings) |
| `modules/WM/mango/monitors/desktop.nix` | ASUS VG289 ×2, 4K@60Hz, 2× scale, matched by make+model+serial (`monitor_rule=`) |
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

## VSCodium Profiles (`modules/GUI/IDE/vscode/`)

HM `programs.vscodium`. Imported on desktop (via `modules/GUI/IDE`) and matebook (directly).

| File | Purpose |
|------|---------|
| `default.nix` | `mkProfile`: base extensions ++ profile extensions, `lib.recursiveUpdate` base settings with profile settings, `mutableUserSettings = true` |
| `extensions.nix` | Plain function `{pkgs}: [...]` — base extension list shared by every profile |
| `settings.nix` | Plain function `{osConfig, config, lib}: {...}` — base settings shared by every profile |
| `profiles/<name>.nix` | Plain function `{pkgs}: {extensions; settings;}` — per-profile additions |
| `ai.nix` | Claude Desktop MCP config + CLAUDE.md (unrelated to profiles) |

| Profile | Adds | Used for |
|---------|------|----------|
| `default` | nothing (base: nix-ide, direnv, just, yaml, toml, shell-format, prettier, claude-code, …) | nix-config, nix-config-private, arr-packages |
| `python` | `detachhead.basedpyright`, `charliermarsh.ruff`; ruff as `[python]` formatter, `basedpyright.importStrategy = "useBundled"` | Python projects (job-kombayn, trendbot, …) |
| `web` | `dbaeumer.vscode-eslint`, `vitest.explorer`, `ms-playwright.playwright` | mis-kitchen (TS/React) |
| `infra` | `opentofu.vscode-opentofu`, `ms-kubernetes-tools.vscode-kubernetes-tools` | gitops, openstack-lab |

**Adding a profile:** create `profiles/<name>.nix`, add `<name> = import ./profiles/<name>.nix {inherit pkgs;};` to the attrset in `default.nix`.

**Notes:**
- HM registers non-default profiles in `globalStorage/storage.json` without `useDefaultFlags`, so profiles share nothing at runtime — base extensions/settings are merged in Nix by `mkProfile`.
- `mutableUserSettings`: HM writes a real file and merges `jq '$dynamic * $static'` — Nix keys win, UI-only keys survive, removed Nix keys are **not** deleted from the file.
- Which profile a folder opens with is VSCodium runtime state (pick once via Profiles menu), not declared in Nix.
- No ms-python: the nixpkgs build lacks the bundled `python_files/lib/jedilsp`, so its Jedi fallback crashes without Pylance (which doesn't run in VSCodium). basedpyright needs `useBundled` without ms-python (basedpyright#1188).
- Microsoft Remote-SSH/Containers and Docker extensions intentionally absent (proprietary / non-OSI license; Dockerfile + compose syntax is built in).

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
| `treefmt.nix` | Sole treefmt config (Nix), used by `parts/formatting.nix` via treefmt-nix and by `nix fmt`. Formatters: alejandra, deadnix, dockfmt, just, prettier, rustfmt, shfmt, statix, toml-sort, yamlfmt, trailing-whitespace-fixer. Excludes `secrets/*`, `*.age`, `*.toml` (global). No standalone `treefmt.toml` — run formatting through `nix fmt`. |
| `statix.toml` | statix linter config — disables `empty_pattern`, `manual_inherit`, `manual_inherit_from`; pins `nix_version = 2.31.2`; ignores `.direnv/`, `result*/`, `secrets/`, `.git/`. |
| `namaka.toml` | [namaka](https://github.com/nix-community/namaka) snapshot test config. Tests discovered from `tests/` subdirs (each with `expr.nix` + optional `format.nix`). Currently disabled in pre-commit. |
| `.yamllint` | yamllint config — extends `default`, disables `document-start` rule. |

The `default` dev shell (`nix develop`) is defined inline in [`parts/devshells.nix`](../parts/devshells.nix) — a `pkgs.mkShell` with the dev tools (age, alejandra, gitleaks, just, nh, pre-commit, sops, statix, …); `ide` comes from `shells/ide.nix`.

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

`justfile` contains task shortcuts (run with `just <recipe>`). Full list:

| Recipe | What it does |
|--------|-------------|
| `deploy-gcp` | `caddy-plugins-update.sh --hashes-only gcp-relay`, then `nh os switch . -H gcp-relay --target-host zeev@gcp-relay`, then `cachix push 4rmcyt-gcp` |
| `deploy-homeserver` / `deploy-matebook` | `nh os switch . -H <host> --target-host zeev@<host>`; `deploy-homeserver` first runs `caddy-plugins-update.sh --hashes-only homeserver` |
| `deploy-local` | `nh os switch .` — for desktop, which is built on-machine, never in CI |
| `update` | `nix flake update`, `just caddy-update`, then build homeserver/matebook/gcp-relay locally |
| `caddy-update` | `tools/scripts/caddy-plugins-update.sh`: bump Caddy plugin tags in `modules/networking/caddy-plugins.json` (latest stable, same major; warns on new major), then rebuild each host's `services.caddy.package.src` FOD and write the `got:` hash back |
| `check` | `nix flake check` |
| `fmt` | `nix fmt` |
| `push-caches` | `cachix push 4rmcyt-$(hostname) /run/current-system` |
| `topology` | Render nix-topology SVGs into `docs/` |

### tools/scripts

Pre-commit and CI helper scripts in `tools/scripts/`:

| Script | Trigger | Purpose |
|--------|---------|---------|
| `check-dangerous-patterns.sh` | pre-commit (`dangerous-shell-patterns` hook), `.nix` + `.sh` files | Blocks `exec zellij/tmux/screen/wezterm` in shell configs — causes lockouts if zsh init runs `exec` unconditionally |
| `caddy-plugins-update.sh` | `just caddy-update` / `just update`; `--hashes-only <host>` from `deploy-gcp` / `deploy-homeserver` | Bumps Caddy plugin tags in `modules/networking/caddy-plugins.json` (latest stable within the current major) and rewrites per-host `withPlugins` hashes from the FOD `got:` line. `--hashes-only` skips the tag bump; trailing host args limit which hosts are checked |
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

Remote hosts are deployed manually via `nh os switch --target-host` over SSH — recipes live in the [`justfile`](../justfile). Build happens on the local machine (no `--build-host`), activation on the target; nh prompts for the remote sudo password itself (`--elevation-strategy auto`). No deploy-rs.

| Host       | Recipe / method |
|------------|-----------------|
| homeserver | `just deploy-homeserver` → `nh os switch . -H homeserver --target-host zeev@homeserver` |
| matebook   | `just deploy-matebook` (same shape, `zeev@matebook`) |
| gcp-relay  | `just deploy-gcp` → deploy `.#gcp-relay`, then push closure to `4rmcyt-gcp` Cachix |
| desktop    | Local: `just deploy-local` (`nh os switch .`) |

Updates are manual everywhere — no auto-upgrade timer.

**ZFS/mount safety:** prefer `nixos-rebuild boot` + reboot over `switch` when config changes affect active mount units. See [Infrastructure.md](Infrastructure.md) ZFS Safety Rules.

## Topology Diagram

`just topology` (or `nix build .#topology.x86_64-linux.config.output`) generates two SVGs via **nix-topology** — physical `main.svg` and `network.svg` — written to `docs/topology.svg` / `docs/topology-network.svg` and embedded in the README. Interface `addresses` in the annotations are descriptive labels, not real IPs, so the committed SVGs expose nothing beyond `docs/Infrastructure.md`.

- **`parts/topology.nix`** — flakeModule wiring + the global topology: `internet`, `isp-router`, the hand-described `router` appliance node (the NixOS host was removed), `switch-office`, `switch-livingroom`, `ap-trusted`, `ap-iot`, and the `trusted` / `iot` / `media` / `work` / `tailnet` network CIDRs. Four hosts are included (desktop, homeserver, matebook, gcp-relay).
- **`modules/topology/default.nix`** — NixOS module imported into `modules.nixos.base` (every host). Per-host `topology.self`: interfaces, network membership, hardware blurbs, a shared `tailscale0` overlay interface. Also blanks extractor `details`/`info` for leaky homeserver services (mosquitto, grafana, kanidm, …) so the committed diagram stays IP-/domain-free.
- 802.1Q is not representable in nix-topology — the office switch is drawn as the trusted segment it mostly carries; the IoT AP hangs off the router's `vlan20` interface.
- `matebook` is decommissioned — config kept for reference, no longer deployed.

## Terraform / OpenTofu

`infra/tf/gcp-relay/` manages GCP infrastructure state for the `gcp-relay` host:

- **GCP resources**: static external IP (`google_compute_address`), GCS bucket for NixOS images, compute instance import
- Remote state backend: GCS bucket (`gcp-relay-nixos-images`, prefix `tofu/state`)
- Variables: `project` (homelab-497717), `region` (us-central1), `zone` (us-central1-a), `image_date` (YYYYMMDD)
- Secrets injected via env vars; never committed

Run: `cd infra/tf/gcp-relay && tofu init && tofu apply -var="image_date=YYYYMMDD"`
