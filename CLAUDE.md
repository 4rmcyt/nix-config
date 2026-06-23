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

`flake.nix` is ~15 lines — it delegates everything to `parts/` via `import-tree ./parts`. All flake-parts modules in `parts/` are auto-imported.

### Key `parts/` files

| File | Purpose |
|------|---------|
| `owner.nix` | `meta.owner.*` — non-secret metadata (username, domain, IPs, email, etc.) |
| `meta.nix` | Defines internal `options.meta` (not a flake output) |
| `flake-parts-modules.nix` | Defines `options.modules` — named deferred modules by class (e.g. `modules.nixos.base`, `modules.homeManager.base`) |
| `shared-nixos-settings.nix` | Contributes to `modules.nixos.base`: nix daemon settings, binary caches, sops, `_module.args = { inherit inputs; }` |
| `home-manager-integration.nix` | Contributes to `modules.nixos.base`: wires HM NixOS module, sops-nix, disko, facter, vscode-server, ucodenix |
| `home-manager-base.nix` | Defines `modules.homeManager.base`: sops HM, overlays, stateVersion |
| `configurations/nixos.nix` | Defines `options.configurations.nixos` (lazyAttrsOf deferredModule → `flake.nixosConfigurations`) |
| `systems.nix` | `systems = ["x86_64-linux"]` |
| `hosts/{desktop,gcp,homeserver,matebook,wsl}/configuration.nix` | Per-host definitions using `configurations.nixos.<name>.module` |

### Host definition pattern

Each host in `parts/hosts/<host>/configuration.nix` follows this pattern:

```nix
{ config, inputs, ... }: let
  inherit (config.meta) owner;
  nixosBase = config.modules.nixos.base;   # capture before entering NixOS scope
in {
  configurations.nixos.<host>.module = { pkgs, ... }: {
    imports = [
      nixosBase                             # shared base (HM wiring, nix settings, sops)
      ../../../hosts/nixos/<host>           # hardware + host-specific NixOS config
      # input modules...
    ];
    home-manager.users.${owner.username}.imports = [
      ../../../home/<host>
      # host-specific HM modules
    ];
  };
}
```

`modules.nixos.base` uses `deferredModule` merge semantics — multiple `parts/` files contribute to it and it is merged before being imported into NixOS.

## Module Layout

```
hosts/nixos/{host}/     # Hardware config + host-specific NixOS settings
home/{host}/            # Home Manager config per host
modules/
  base/                 # Core system (logging, msmtp, distributed-builds)
  options/              # my.defaults.* options (user, email, domain, IPs, timezone, locale)
  roles/                # Role compositions (desktop, server, media-server, monitoring)
  DE/                   # Desktop environments (KDE, COSMIC)
  WM/                   # Window managers (niri + noctalia-shell)
  GUI/                  # GUI apps (firefox, kitty, zed, obsidian, etc.)
  TUI/                  # Terminal tools (zsh, zellij, atuin, ai-tools)
  services/             # k3s, nixarr, homepage, ollama, paperless, etc.
  networking/           # SSH, tailscale, wireguard, traefik, cloudflared
  security/             # kanidm, crowdsec, fail2ban
  monitoring/           # prometheus, grafana, loki
  database/             # postgresql, redis, couchdb
  disko/                # Declarative disk partitioning per host
  lib/                  # Helpers (sops, tmpfiles, users)
parts/                  # flake-parts modules (auto-imported via import-tree)
secrets/                # sops-encrypted YAML (NEVER commit plaintext)
overlays/               # Package customizations
```

## Key Conventions

**Metadata:** Use `config.meta.owner.*` in flake-parts scope, and `config.my.defaults.*` in NixOS module scope. Both resolve to the same values from `parts/owner.nix` / `modules/options/defaults.nix`. Never hardcode them.

**Secrets:** sops-nix + age. Age key at `/root/.config/sops/age/keys.txt` (system) and `~/.config/sops/age/keys.txt` (HM). Reference secrets as `config.sops.secrets.<name>.path`. Never run `sops encrypt` via tool call — give the user the command.

**Formatting:** `nix fmt` via treefmt. Uses alejandra (not nixfmt-rfc-style) for Nix. Always format before committing.

**Commits:** Conventional style: `type(scope): description`. Scope = module name or host.

**NixOS vs HM boundary:** System-level config belongs in NixOS modules. User-level config belongs in Home Manager. Use single-responsibility modules.

**Verify config keys:** Before writing any daemon config key (bluetoothd `main.conf`, pipewire, wireplumber, etc.), check the actual schema in the nix store or binary `--help`. Do not guess option names.

## Documentation Maintenance

**Before every commit** — check if the changes affect either reference doc and update accordingly:

| If you changed… | Update |
|-----------------|--------|
| Host config, services, networking, ZFS, monitoring, secrets | [docs/Infrastructure.md](docs/Infrastructure.md) |
| Flake structure, `parts/`, module layout, WM stack, deploy, options system | [docs/Architecture.md](docs/Architecture.md) |

Rules:
- New service added/removed → update the services table (mark disabled rather than delete)
- Port, URL, or hostname changed → update the relevant table row
- ZFS layout changed → update the Storage section
- New flake input wired into a host → update Architecture.md Host Wiring section
- Security tool replaced (e.g. Authelia → Kanidm) → update both the service table and any prose that references the old tool by name

## CRITICAL: homeserver ZFS / Rebuild Safety Rules

**NEVER run `nixos-rebuild switch` while `zfs send` is in progress.** Rebuild restarts affected mount units, killing the transfer and potentially crashing the server.

**When config changes affect active mount units (`data.mount`, etc.):** use `nixos-rebuild boot` + reboot instead of `switch`. The `switch` path tries to restart mounts live, which kills services with open file handles and crashes SSH.

**When adding a new ZFS pool:**
1. Add `boot.zfs.extraPools = ["poolname"]` to hardware-configuration.nix FIRST
2. Only then run `nixos-rebuild switch`
3. Without `extraPools`, NixOS won't generate `zfs-import-<pool>.service`, causing `data.mount` to fail on rebuild/reboot

**Before any destructive or hard-to-reverse action on homeserver** (nixos-rebuild switch, zfs destroy, zpool remove, reboot during migration):
- Will this interrupt any running operation? (zfs send, mkvmerge, active downloads)
- Will this restart a mount unit that something is actively using?
- If unsure — warn the user BEFORE they run it.

## Reference Docs

Read these before working on the relevant area — they are the authoritative detail source:

| When you're working on… | Read |
|-------------------------|------|
| Any homeserver task (services, ZFS, networking, monitoring) | [docs/Infrastructure.md](docs/Infrastructure.md) |
| Flake structure, module wiring, desktop WM, options system, deploy | [docs/Architecture.md](docs/Architecture.md) |

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

**ALWAYS search the internet (tavily) before touching any unfamiliar tool's config.** Never make speculative changes — find the documented solution or GitHub issue first.
