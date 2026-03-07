# nix-config Claude Instructions

## Project Layout

Flake with 4 NixOS hosts: `desktop`, `homeserver`, `matebook`, `wsl`

```
hosts/nixos/{host}/     # System config + hardware
home/{host}/            # Home Manager per host
modules/
  base/                 # Core system (logging, msmtp, distributed-builds)
  options/              # my.defaults.*, my.network.*, my.security.*
  services/             # k3s, nixarr, homepage, ollama, paperless, etc.
  networking/           # SSH, tailscale, wireguard, traefik, cloudflared
  security/             # authelia, lldap, fail2ban
  monitoring/           # prometheus, grafana, loki
  database/             # postgresql, redis, couchdb
  disko/                # Declarative disk partitioning per host
secrets/                # sops-encrypted (NEVER commit plaintext)
```

## Key Conventions

- Use `my.defaults.*` options — never hardcode user, email, domain, IPs
- Secrets via sops-nix: reference as `config.sops.secrets.<name>.path`
- Format: `nix fmt` (alejandra, deadnix, statix, shfmt, yamlfmt)
- Commits: conventional style `type(scope): description`

## homeserver ZFS Layout

- `zroot` — Samsung 256GB NVMe — OS, nix, home, log, postgresql, containers
- `zdata` — Corsair MP600 Pro LPX 2TB NVMe — `/data` (media, downloads)
- `zbackup` — Patriot P210 1TB SATA SSD — `/backup` (planned)
- `boot.zfs.extraPools = ["zdata"]` in hardware-configuration.nix

## CRITICAL: homeserver Rebuild Rules

**NEVER `nixos-rebuild switch` when:**
- `zfs send` is in progress — it restarts mount units, kills the transfer, crashes the server
- Any active mount unit has open file handles (jellyfin, qbittorrent, radarr, sonarr all use /data)

**When config changes affect active mount units (data.mount etc.):**
- Use `nixos-rebuild boot` + `reboot` instead of `switch`
- `switch` restarts mounts live → kills services → SSH drops → server crashes
- `boot` safely sets next boot target without touching running units

**When adding a new ZFS pool:**
1. Add `boot.zfs.extraPools = ["poolname"]` to hardware-configuration.nix FIRST
2. Use `nixos-rebuild boot` + reboot (not switch)
3. Without `extraPools`, NixOS won't generate `zfs-import-<pool>.service` → `data.mount` fails

## CRITICAL: General Safety Rules

Before any destructive/hard-to-reverse action (nixos-rebuild switch, zfs destroy,
zpool remove, reboot during migration):
- Will this interrupt a running operation? (zfs send, mkvmerge, active downloads)
- Will this restart a mount unit that something is actively using?
- Warn the user BEFORE they run it, not after
