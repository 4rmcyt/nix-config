# Infrastructure

Domain: `example.com`  
Timezone: `America/Edmonton`  
Tailnet login server: `https://hs.example.com` (self-hosted Headscale)

---

## Hosts

### homeserver

**Role:** Primary home server — все сервисы, мониторинг, DNS, VPN hub  
**LAN IP:** `192.168.1.165`  
**Tailscale:** exit node + subnet router (`192.168.1.0/24`)

#### Storage (ZFS)

| Pool     | Device                             | Mount      | Notes                               |
|----------|------------------------------------|------------|-------------------------------------|
| `zroot`  | Samsung 256GB NVMe (`nvme1`)       | `/`        | OS, `/nix`, `/home`, `/var/log`, PostgreSQL, containers |
| `zdata`  | Corsair MP600 Pro LPX 2TB NVMe     | `/data`    | Media, downloads. `autotrim=on`, `sync=disabled` |
| `zbackup`| Patriot P210 1TB SATA SSD          | `/backup`  | Local backups. Imported non-blocking via `boot.postBootCommands` (not `extraPools`) so failure doesn't block boot |

`zroot` datasets: `reserved` (20G), `nix`, `root`, `home`, `log`, `postgresql`, `containers`, `kanidm`  
`zroot/nix` and `zroot/home` have `@empty` snapshots for rollback.

#### ZFS Safety Rules

**NEVER `nixos-rebuild switch` when `zfs send` is in progress** — it restarts mount units, kills the transfer, crashes the server.

**When config changes affect active mount units** (`data.mount`, etc.) — use `nixos-rebuild boot` + reboot instead. `switch` restarts mounts live → kills services with open handles (jellyfin, qbittorrent, radarr, sonarr) → SSH drops.

**When adding a new ZFS pool:**
1. Add `boot.zfs.extraPools = ["poolname"]` to `hardware-configuration.nix` first
2. Then `nixos-rebuild boot` + reboot — never `switch`
3. Without `extraPools`, NixOS won't generate `zfs-import-<pool>.service` → mount fails

#### Networking

- SSH on port **2222** (port 22 has no listener)
- Unbound DNS resolver: interfaces `tailscale0`, `enp0s31f6`; NextDNS profile `nextdns0`
- Tailscale with DNSSEC: NextDNS upstream, split DNS for `example.com` → homeserver

#### Nix Build

- `cores = 4`, `max-jobs = 4`, `big-parallel` feature enabled
- `nix-builder` system user accepts remote builds from desktop

---

### desktop

**Role:** Primary workstation — Niri WM, gaming, dev tools  
**LAN IP:** `192.168.1.118` (ethernet) / `192.168.1.239` (WiFi)  
**GPU:** NVIDIA RTX 3050 8GB  
**CPU:** Ryzen 7000 series (Zen 4)  
**RAM:** 60 GB

#### Storage (ZFS)

ZFS root pool with systemd-tmpfiles suppression (`--exclude-prefix`) to avoid `chattr` warnings.

#### Desktop Stack

- **WM:** Niri (niri-flake NixOS module, `pkgs.niri` 25.11, not niri-flake stable)
- **DM:** greetd (auto-login into Niri session)
- **Shell:** noctalia-shell (quickshell-based bar/shell)
- **Theming:** Stylix + matugen dynamic colors
- **Portal:** `xdg-desktop-portal-gnome` + `xdg-desktop-portal-gtk`
- **nirinit:** enabled (smooth session init)

#### Nix Build

- `cores = 0` (all), `max-jobs = auto`, `big-parallel + kvm` features
- Sends builds to homeserver via `nix-builder` user over SSH

---

### matebook

**Role:** Laptop — portable workstation  
**WiFi IP:** `192.168.1.132`

- Niri WM + noctalia-shell
- Nix daemon: **determinate** (vs lix on desktop/homeserver)
- Tailscale client with magic rollback enabled for remote deploys

---

### wsl

**Role:** WSL2 environment on Windows  
- Minimal NixOS config — `services.timesyncd.enable = lib.mkForce false` (WSL manages time sync)
- HM config in `home/wsl/`: TUI/common, TUI/zsh, TUI/atuin, GUI/terminal/wezterm, basic packages

---

### gcp-relay

**Role:** GCP e2-micro — VPN control plane + DERP relay  
**Public IP:** `203.0.113.1`  
**Region:** GCP US Central (Iowa)

- **Headscale** coordination server: `https://hs.example.com` (port 8080 behind Caddy)
- **Headplane** web UI: proxied by Caddy (`inputs.headplane` flake, with custom `headplane-ssh-wasm` buildPhase patch)
- **DERP** relay: region ID 901, `gcp-us-central1`, STUN on `0.0.0.0:3478`
- **Caddy** TLS termination (replaces Traefik for this host)
- **CrowdSec** nftables bouncer: remote LAPI via Tailscale pointing to homeserver
- **fail2ban**: SSH jail, incremental bans up to 168h
- **Auto-upgrade**: daily at 04:00, `nixos-rebuild boot`, flake `github:4rmcyt/nix-config#gcp-relay`
- Root disk: 10 GB, zram swap, journal capped at 500 MB / 14 days
- node_exporter scraped by homeserver Prometheus

---

## Networking Stack (homeserver)

### Traefik (reverse proxy)

- HTTP → HTTPS redirect; wildcard TLS via Cloudflare DNS-01 ACME
- Plugins (local, from Nix store): **crowdsec-bouncer**, **traefik-geoblock**
- Middlewares applied to all routers: `security-headers`, `crowdsec`
- Public-facing `hass`: additionally `rate-limit` + `geoblock` (CA/US only)
- Metrics endpoint on `127.0.0.1:8080`; internal API on `127.0.0.1:8083` (homepage widget)
- Access logs: JSON, errors + slow requests only, 14-day rotation

### Headscale (Tailnet control plane)

Running on GCP relay. Split DNS: `example.com` → `100.64.0.3` (homeserver Tailscale IP).  
Magic DNS base domain: `ts.example.com`. DERP: GCP US Central + Tailscale default map.

SSH config uses MagicDNS hostnames (`homeserver.ts.example.com`, `matebook.ts.example.com`, `gcp-relay.ts.example.com`) so SSH works from any network without hardcoded LAN IPs. Operator mode enabled on desktop + matebook (`extraSetFlags = ["--operator=zeev"]`) so `tailscale file cp` works without sudo.

### Unbound (recursive DNS)

On homeserver, listening on Tailscale + LAN interfaces. Forwards to NextDNS profile `nextdns0` with DNSSEC validation. Desktop and matebook use homeserver as resolver.

### CrowdSec

- **homeserver**: LAPI at `127.0.0.1:8088`; Traefik bouncer (stream mode); collections: `linux`, `sshd`, `traefik`
- **gcp-relay**: nftables bouncer; remote LAPI via Tailscale pointing to homeserver
- Whitelists: Tailscale CGNAT `100.64.0.0/10`, LAN `192.168.1.0/24`, Cloudflare IPs

### Cloudflared

Cloudflare Tunnel for select services (configured in `modules/networking/cloudflared/`). Tunnel config rendered by sops template at runtime.

### NFS

NFS server on homeserver (`modules/networking/nfs/`); NFS client on desktop (`modules/networking/nfs-client/`).

### UPS (NUT)

NUT server on homeserver; NUT client on desktop. Prometheus NUT exporter scrapes battery/load metrics.

---

## Services (homeserver)

Most services are behind Traefik at `*.example.com`. A subset is additionally exposed via **Cloudflare Tunnel** (no open inbound ports required).

### Cloudflare Tunnel

Active tunnels (proxied through `localhost:443` → Traefik):

| Hostname                 | Purpose                      |
|--------------------------|------------------------------|
| `hass.example.com`      | Home Assistant (public)      |
| `livesync.example.com`  | CouchDB / Obsidian LiveSync  |
| `cal.example.com`       | Radicale CalDAV/CardDAV      |
| `ntfy.example.com`      | Push notifications           |

Tunnel credentials in `secrets/cloudflare_tunnel_credentials.bin` + `secrets/cloudflare.yaml`. Config rendered by sops template at runtime.

### Media

| Service         | Port  | URL                           | Notes                              |
|-----------------|-------|-------------------------------|------------------------------------|
| Jellyfin        | 8096  | `jellyfin.example.com`       | Media server                       |
| qBittorrent     | 8081  | `qb.example.com`             | via nixarr                         |
| Sonarr          | 8990  | `sonarr.example.com`         | TV                                 |
| Radarr          | 7878  | `radarr.example.com`         | Movies                             |
| Prowlarr        | 9696  | `prowlarr.example.com`       | Indexer                            |
| Bazarr          | 6767  | `bazarr.example.com`         | Subtitles                          |
| Lidarr          | 8686  | `lidarr.example.com`         | Music                              |
| LazyLibrarian   | 5299  | `lazylibrarian.example.com`  | Books — ephraim-nur overlay        |
| Kapowarr        | 5656  | `kapowarr.example.com`       | Comics                             |
| Seerr           | 5055  | `seerr.example.com`          | Request management                 |
| Audiobookshelf  | 9292  | `audiobookshelf.example.com` | Audiobooks                         |
| Recyclarr       | —     | (no UI)                       | Auto-sync quality profiles to *arr |
| Flaresolverr    | 8191  | (internal only)               | Cloudflare bypass for Prowlarr     |
| Dispatcharr     | 9191  | `dispatcharr.example.com`    | Stream dispatch — OCI container    |

### Reading / Library

| Service   | Port  | URL                      | Notes             |
|-----------|-------|--------------------------|-------------------|
| Komga     | 8087  | `komga.example.com`     |                   |
| Komf      | 8085  | `komf.example.com`      |                   |
| Miniflux  | 8086  | `miniflux.example.com`  |                   |

### Identity / SSO

| Service  | Port  | URL                    | Notes                                                     |
|----------|-------|------------------------|-----------------------------------------------------------|
| Kanidm   | 3013  | `idm.example.com`     | OIDC provider for Grafana, Miniflux, Jellyfin, Audiobookshelf, Headscale. Self-signed TLS internally, Traefik terminates externally via `insecureSkipVerify`. Provisioned declaratively via sops secrets. |

### Productivity / Home

| Service        | Port  | URL                        | Notes                         |
|----------------|-------|----------------------------|-------------------------------|
| Home Assistant | 8123  | `hass.example.com`        | Podman OCI container; Alexa Smart Home; WoL for desktop; geoblock + rate-limit |
| Homepage       | 8082  | `home.example.com`        | Dashboard (pinned v1.13.1 overlay) |
| Radicale       | 5232  | `cal.example.com`         | CalDAV/CardDAV                |
| ntfy           | 9991  | `ntfy.example.com`        | Push notifications            |
| Microbin       | 8069  | `microbin.example.com`    | Paste bin                     |
| Atuin server   | 8881  | `atuin.example.com`       | Shell history sync            |
| CouchDB        | 5984  | `livesync.example.com`    | Obsidian LiveSync backend     |

### AI / Local LLM

| Service   | Notes                                                                    |
|-----------|--------------------------------------------------------------------------|
| llama-cpp | Desktop only (`modules/TUI/ai-tools/llama-cpp`). Current model: Gemma 4 E4B |

---

## Monitoring Stack (homeserver)

```
node_exporter (all hosts) ──┐
NUT exporter                ├──► Prometheus :9090 ──► Grafana :3003  ──► grafana.example.com
Traefik metrics :8080       │         │
CrowdSec metrics :6060      │         └──► Alertmanager ──► alertmanager-ntfy ──► ntfy
                            │
Systemd journal ────────────┤──► Alloy ──► Loki :3100
Traefik access.log ─────────┘
```

- **Prometheus** scrape targets: homeserver, desktop, matebook, gcp-relay node exporters; NUT; Traefik; CrowdSec; Prometheus self
- **Grafana** OIDC via Kanidm; backend PostgreSQL; datasources: Prometheus + Loki; dashboards from `modules/monitoring/dashboards/`
- **Loki** retention 30 days; TSDB schema v13; filesystem storage; Loki alert rules in `modules/monitoring/alerts/loki-rules.yaml`
- **Alloy** ships: Traefik access log, systemd journal (last 12h); Python container log-level fix pipeline
- **Alertmanager** → **alertmanager-ntfy** bridge → ntfy topic `alerts`
- **GeoIP** monthly auto-update from db-ip.com (city MMDB, no account required)
- Alert rules: `modules/monitoring/alerts/homeserver.yaml` (Prometheus), `modules/monitoring/alerts/loki-rules.yaml` (Loki)

---

## Databases (homeserver)

| Service    | Notes                                          |
|------------|------------------------------------------------|
| PostgreSQL | Used by: Grafana, Miniflux, Atuin, others       |
| Redis      | Cache layer for various services               |
| CouchDB    | Obsidian LiveSync backend (`livesync.example.com`) |

---

## Secrets Layout

All encrypted with age. Key file: `/root/.config/sops/age/keys.txt` (all hosts), `~/.config/sops/age/keys.txt` (HM).

```
secrets/
  # Global / shared
  common.yaml                          # git_access_token, nix_access_token, gemini_api_key, defaults
  defaults.yaml                        # default option values
  system.yaml                          # homeserver SSH host keys
  ssh.yaml                             # SSH keys

  # Per-host Tailscale auth
  tailscale-homeserver.yaml
  tailscale-desktop.yaml
  tailscale-matebook.yaml
  tailscale-gcp.yaml

  # Nix remote builds
  nix-builder-homeserver.yaml          # nix-builder SSH private key
  nix-builder-keys.yaml                # nix-builder authorized keys

  # Networking / TLS
  cloudflare_acme_credentials.env      # CF_DNS_API_TOKEN for Traefik ACME
  cloudflare.yaml                      # Cloudflare API token
  cloudflare.pem / cloudflare.key      # TLS cert/key
  cert.pem / key.pem                   # Additional TLS material
  cloudflare_tunnel_credentials.bin    # Cloudflare Tunnel credentials
  cloudflare-prometheus-exporter.yaml  # Cloudflare exporter token
  tailscale-prometheus-exporter.env    # Tailscale exporter token
  nextdns.yaml                         # NextDNS API key
  wg.conf                              # WireGuard config
  gcp-relay-host-ed25519              # GCP SSH host key
  gcp-relay-age-key                    # GCP age encryption key
  gcp.yaml                             # GCP credentials

  # Security
  crowdsec.yaml                        # Traefik bouncer API key (homeserver)
  crowdsec-gcp.yaml                    # nftables bouncer API key (gcp-relay)
  hetzner_pass.yaml                    # Hetzner password

  # Databases
  postgresql.yaml                      # DB passwords (grafana, atuin, etc.)
  redis.yaml                           # Redis password
  couchdb.yaml                         # CouchDB admin credentials

  # Monitoring
  grafana.yaml                         # admin password, OIDC secret, secret key
  loki.yaml                            # Loki credentials
  nut.yaml                             # NUT exporter password

  # Identity
  kanidm.yaml                          # Kanidm admin credentials, OIDC secrets
  headscale.yaml                       # Headscale config secrets
  headplane.yaml                       # Headplane credentials

  # Services
  atuin.yaml                           # Atuin server credentials
  miniflux.yaml / miniflux.env         # Miniflux admin + env secrets
  homepage.env                         # Homepage API keys
  ntfy.yaml                            # ntfy auth config
  radicale.yaml                        # Radicale user credentials
  radicale_users.txt                   # Radicale htpasswd file
  microbin.yaml                        # Microbin admin secret
  hass-alexa.yaml                      # Home Assistant Alexa skill credentials
  lazylibrarian.yaml                   # LazyLibrarian credentials
  k3s.yaml                             # k3s token (service disabled)
  recyclarr.yaml                       # Recyclarr API keys
  restic.yaml                          # Restic backup repository + password
  medialib.yaml                        # Media library credentials
  gmail_conf.yaml                      # Gmail / msmtp config
```
