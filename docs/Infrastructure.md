# Infrastructure

Domain: `example.com`  
Timezone: `America/Edmonton`  
Tailnet login server: `https://hs.example.com` (self-hosted Headscale)

---

## Hosts

### homeserver

**Role:** Primary home server — all services, monitoring, DNS, VPN hub  
**LAN IP:** `192.168.1.165`  
**Tailscale:** exit node + subnet router (`192.168.1.0/24`)

#### Storage (ZFS)

| Pool     | Device                             | Mount      | Notes                               |
|----------|------------------------------------|------------|-------------------------------------|
| `zroot`  | Samsung 256GB NVMe (`nvme1`)       | `/`        | OS, `/nix`, `/home`, `/var/log`, PostgreSQL, containers |
| `zdata`  | Corsair MP600 Pro LPX 2TB NVMe     | `/data`    | Media, downloads. `autotrim=on`, `sync=disabled` |
| `zbackup`| Patriot P210 1TB SATA SSD          | `/backup`  | Local backups. Non-blocking import via `boot.postBootCommands` |

`zroot` datasets: `reserved` (20G), `nix`, `root`, `home`, `log`, `postgresql`, `containers`, `authentik`, `vaultwarden`  
`zroot/nix` and `zroot/home` have `@empty` snapshots for rollback.

#### Networking

- SSH on port **2222** (port 22 is Cowrie honeypot DNAT via Podman)
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

#### Nix Build

- `cores = 0` (all), `max-jobs = auto`, `big-parallel + kvm` features
- Sends builds to homeserver via `nix-builder` user over SSH

---

### matebook

**Role:** Laptop — portable workstation  
**WiFi IP:** `192.168.1.132`

- Niri WM + noctalia-shell
- Tailscale client with magic rollback enabled for remote deploys

---

### wsl

**Role:** WSL2 environment on Windows  
- Minimal config — no HM, no extra modules
- `services.timesyncd.enable = lib.mkForce false` (WSL manages time sync)

---

### gcp-relay

**Role:** GCP e2-micro — VPN control plane + DERP relay  
**Public IP:** `203.0.113.1`  
**Region:** GCP US Central (Iowa)

- **Headscale** coordination server: `https://hs.example.com` (port 8080 behind Caddy)
- **Headplane** web UI: proxied by Caddy
- **DERP** relay: region ID 901, `gcp-us-central1`, STUN on `0.0.0.0:3478`
- **Caddy** TLS termination (replaces Traefik for this host)
- **CrowdSec nftables bouncer**: remote LAPI via Tailscale pointing to homeserver
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

Cloudflare Tunnel for select services (configured in `modules/networking/cloudflared/`).

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
| slskd           | 5030  | `slskd.example.com`          | Soulseek client                    |
| Dispatcharr     | 9191  | `dispatcharr.example.com`    | Stream dispatch                    |

### Reading / Library

| Service   | Port  | URL                      |
|-----------|-------|--------------------------|
| Kavita    | 5000  | `kavita.example.com`    |
| Komga     | 8087  | `komga.example.com`     |
| Komf      | 8085  | `komf.example.com`      |
| Miniflux  | 8086  | `miniflux.example.com`  |

### Productivity / Home

| Service        | Port  | URL                        | Notes                         |
|----------------|-------|----------------------------|-------------------------------|
| Home Assistant | 8123  | `hass.example.com`        | Podman OCI container; Alexa Smart Home; WoL for desktop; geoblock + rate-limit |
| Homepage       | 8082  | `home.example.com`        | Dashboard                     |
| Radicale       | 5232  | `cal.example.com`         | CalDAV/CardDAV                |
| ntfy           | 9991  | `ntfy.example.com`        | Push notifications            |
| Microbin       | 8069  | `microbin.example.com`    | Paste bin                     |
| Vaultwarden    | 8222  | `vault.example.com`       | Password manager              |
| Atuin server   | 8881  | `atuin.example.com`       | Shell history sync            |
| CouchDB        | 5984  | `livesync.example.com`    | Obsidian LiveSync backend     |

### AI / Local LLM (disabled)

Ollama + Open-WebUI are present in `modules/services/ollama/` but commented out in `modules/services/default.nix`.  
Config when enabled: `acceleration = "cuda"`, models: `codellama:7b`, `codellama:13b`, `phi3:mini-4k`.  
Ports: Ollama `:11434`, Open-WebUI `:11435`.

---

## Monitoring Stack (homeserver)

```
node_exporter (all hosts) ──┐
NUT exporter                ├──► Prometheus :9090 ──► Grafana :3003  ──► grafana.example.com
Traefik metrics :8080       │         │
CrowdSec metrics :6060      │         └──► Alloy ──► Loki :3100
                            │                  ▲
Systemd journal ────────────┘          Traefik access.log
```

- **Prometheus** scrape targets: homeserver, desktop, matebook, gcp-relay node exporters; NUT; Traefik; CrowdSec; Prometheus self
- **Grafana** OIDC via Authelia; backend PostgreSQL; datasources: Prometheus + Loki
- **Loki** retention 30 days; TSDB schema v13; filesystem storage
- **Alloy** ships: Traefik access log, systemd journal (last 12h)
- **GeoIP** monthly auto-update from db-ip.com (city MMDB, no account required)
- Alert rules: `modules/monitoring/alerts/homeserver.yaml`
- Dashboards provisioned from `modules/monitoring/dashboards/`

---

## Databases (homeserver)

| Service    | Notes                                          |
|------------|------------------------------------------------|
| PostgreSQL | Used by: Grafana, Miniflux, Atuin, others       |
| Redis      | Cache layer for various services               |
| CouchDB    | Obsidian LiveSync backend (`livesync.example.com`) |

---

## Secrets Layout

```
secrets/
  common.yaml                     # git_access_token, nix_access_token, gemini_api_key, defaults
  system.yaml                     # homeserver SSH host keys
  tailscale-homeserver.yaml       # Tailscale auth key (homeserver)
  tailscale-desktop.yaml          # Tailscale auth key (desktop)
  tailscale-matebook.yaml         # Tailscale auth key (matebook)
  cloudflare_acme_credentials.env # CF_DNS_API_TOKEN for Traefik ACME
  grafana.yaml                    # admin password, OIDC secret, secret key
  postgresql.yaml                 # DB passwords (grafana, etc.)
  crowdsec.yaml                   # Traefik bouncer API key
  crowdsec-gcp.yaml               # nftables bouncer API key (gcp-relay)
  gcp-relay-host-ed25519          # (binary) GCP SSH host key
  nix-builder-homeserver.yaml     # nix-builder SSH private key
  nut.yaml                        # NUT exporter password
```

All encrypted with age. Key file path: `/root/.config/sops/age/keys.txt` (all hosts).
