# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
nix fmt                          # Format all files (alejandra, deadnix, statix, prettier, shfmt, yamlfmt)
nix flake check                  # Validate flake outputs
nix build .#nixosConfigurations.<host>.config.system.build.toplevel  # Build a host
```

**NEVER run `nix build`, `nixos-rebuild`, or any build/deploy commands.** The user builds himself. Write code changes only — stop when done.

**NEVER run `sudo`.** It is blocked by a hook. Write the command and ask the user to run it.

## Flake Architecture (flake-parts + import-tree)

`flake.nix` is an `inputs` block plus a 6-line `outputs` that delegates everything to `parts/` via `import-tree ./parts`. Every `.nix` under `parts/` is auto-imported.

**[docs/Architecture.md](docs/Architecture.md) is the canonical reference** for `parts/` file responsibilities, the named deferred modules, host wiring, and the options system. Don't duplicate that detail here — read it and keep it current.

Quick orientation only:

- Named deferred modules (`options.modules`, defined in `flake-parts-modules.nix`), merged via `deferredModule` semantics from several `parts/` files, then imported per host:
  - `modules.nixos.base` — nix daemon/caches/sops + sops-nix/disko/nix-topology wiring. Every host.
  - `modules.nixos.hm` — Home Manager NixOS module. Opt-in per host (not gcp-relay).
  - `modules.nixos.bareMetal` — facter + ucodenix + gnupg + nix dev tools. Physical hosts only (not the gcp-relay VM).
  - `modules.nixos.workstationGui` / `modules.homeManager.workstation` — GUI stack, desktop + matebook.
- `parts/hosts/<host>/configuration.nix` defines `configurations.nixos.<host>.module`, capturing the deferred modules from `config.modules.*` before entering NixOS scope and listing them plus `../../../hosts/nixos/<host>` and input modules in `imports`.
- Identity + LAN topology come from the private `private` flake input, surfaced as `my.defaults.*` / `my.network.*` (see `modules/options/`). `parts/owner.nix` only pulls `meta.owner.username` from it for flake-parts-scope wiring.

## Module Layout

```
hosts/nixos/{host}/     # Hardware config + host-specific NixOS settings
home/{host}/            # Home Manager config per host
modules/
  base/                 # Core system (logging, msmtp)
  options/              # my.defaults.* (identity/locale) + my.network.* (addresses, ports)
  WM/                   # Window managers (niri + mango, both w/ noctalia-shell, gtk, mime) — desktop:mango, matebook:niri
  GUI/                  # GUI apps (firefox, chrome, zed, obsidian, terminal, IDE, etc.)
  TUI/                  # Terminal tools (zsh, zellij, atuin, ai-tools, llama-cpp)
  services/             # nixarr, homepage, miniflux, home-assistant, atuin-server, etc.
                        # k3s, argocd — disabled (modules exist)
  networking/           # SSH, tailscale, traefik, headscale, cloudflared, caddy, nfs, etc.
  security/             # kanidm, crowdsec, fail2ban
  monitoring/           # split by concern: grafana.nix, loki.nix, prometheus.nix,
                        # alertmanager.nix, alloy-server.nix, geoip.nix (default.nix
                        # just imports them); client-side: alloy-client.nix, node-exporter-client.nix
  database/             # postgresql, redis, couchdb
  disko/                # Declarative disk partitioning per host
  users/                # Per-user NixOS config (zeev)
  backup/               # Backup tooling (restic)
  containers/           # Podman container support
parts/                  # flake-parts modules (auto-imported via import-tree)
secrets/                # sops-encrypted YAML (NEVER commit plaintext)
```

## Key Conventions

**Metadata:** In NixOS module scope use `config.my.defaults.*` / `config.my.network.*`; in flake-parts scope use `config.meta.owner.*` (currently just `username`). Both ultimately come from the private `private` flake input (`inputs.private.lib.{identity,network}` — schema in `modules/options/private-example.nix`). Never hardcode them.

**Secrets:** sops-nix + age. Age key at `/root/.config/sops/age/keys.txt` (system) and `~/.config/sops/age/keys.txt` (HM). Reference secrets as `config.sops.secrets.<name>.path`. Never run `sops encrypt` via tool call — give the user the command.

**Formatting:** `nix fmt` via treefmt. Uses alejandra (not nixfmt-rfc-style) for Nix. Always format before committing.

**Commits:** Conventional style: `type(scope): description`. Scope = module name or host.

**NixOS vs HM boundary:** System-level config belongs in NixOS modules. User-level config belongs in Home Manager. Use single-responsibility modules.

**Verify config keys:** Before writing ANY config key for ANY app, terminal, or daemon — fetch the official docs first (`mcp__fetch__fetch` or `tavily`). Never guess option names. Applies to: terminal emulators (rio, ghostty, alacritty, wezterm, kitty), daemons (bluetoothd, pipewire, wireplumber), HM/NixOS modules, everything. Read the schema, then write. No exceptions.

## Reference Docs — Read First, Update Always

**Before working on any area, read the relevant doc.** They are the authoritative detail source — do not guess at ports, URLs, module paths, or service state.

| When working on… | Read first |
|------------------|------------|
| Any homeserver task (services, ZFS, networking, monitoring) | [docs/Infrastructure.md](docs/Infrastructure.md) |
| Flake structure, `parts/`, module layout, WM stack, options system, deploy | [docs/Architecture.md](docs/Architecture.md) |
| GitHub Actions workflows, CI/CD pipeline, `.github/` | [docs/CI-CD.md](docs/CI-CD.md) |

**After every change, update the relevant doc immediately** — not at commit time, but as part of the same edit session.

| If you changed… | Update |
|-----------------|--------|
| Service added or removed | [docs/Infrastructure.md](docs/Infrastructure.md) — add or delete the row entirely (do not leave "disabled" rows for non-existent services) |
| Port, URL, or hostname changed | Update the relevant table row |
| ZFS layout changed | Update the Storage section |
| New flake input wired into a host | [docs/Architecture.md](docs/Architecture.md) — Host Wiring section |
| Flake structure, `parts/` files, module layout changed | [docs/Architecture.md](docs/Architecture.md) |
| Security tool replaced | Update both the service table and any prose referencing the old tool |
| `.github/workflows/*` changed (triggers, jobs, matrix, secrets) | [docs/CI-CD.md](docs/CI-CD.md) |

**When adding a new ZFS pool:**
1. Add `boot.zfs.extraPools = ["poolname"]` to hardware-configuration.nix FIRST
2. Only then run `nixos-rebuild switch`
3. Without `extraPools`, NixOS won't generate `zfs-import-<pool>.service`, causing `data.mount` to fail on rebuild/reboot

## MCP Tool Routing

| Task | Tool |
|------|------|
| GitHub PRs, issues, repos, code search | `github` MCP — never use `gh` CLI |
| NixOS packages, options, Home Manager docs | `mcp-nixos` — always first for Nix queries |
| Web search | `tavily` |
| Fetch specific URL | `fetch` |
| Files in this repo | `filesystem` MCP |
| Kubernetes (k3s) | `kubernetes` |
| Persist context across sessions | `memory` |
| OpenTofu registry, providers, modules, resources | `opentofu` MCP |

**ALWAYS search the internet (tavily) before touching any unfamiliar tool's config.** Never make speculative changes — find the documented solution or GitHub issue first.
