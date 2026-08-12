# Infrastructure

Domain: `example.com`  
Timezone: `America/Edmonton`  
Tailnet login server: `https://hs.example.com` (self-hosted Headscale)

---

## Hosts

### router

**Role:** Network router — VLAN segmentation, NAT, DHCP, DNS, Tailscale subnet relay  
**Hardware:** Sophos SG110/120 — Intel Atom D525, 2 GB RAM, legacy BIOS  
**WAN IP:** DHCP from ISP router (`192.168.1.254`)  
**Tailscale:** subnet router (advertises `192.168.30.0/24` media VLAN)

#### Physical Interfaces

| Interface | Role | Connected to |
|-----------|------|-------------|
| `enp1s0` | WAN | ISP router (DHCP) |
| `enp2s0` | Office trunk (802.1Q) | TL-SG108E #1 `192.168.1.111` — vlan10 + vlan20 + vlan40 |
| `enp3s0` | Media (physical, no VLAN) | TL-SG108E #2 `192.168.30.112` — all ports untagged |
| `enp4s0` | Trusted AP (physical) | ISP AP (trusted WiFi) |

Interface names are placeholders — verify with `ip link` on hardware after first boot.

#### Network Zones

| Zone | Interface | Subnet | Gateway | DNS | Purpose |
|------|-----------|--------|---------|-----|---------|
| trusted | `vlan10` + `enp4s0` | `192.168.1.0/24` | `192.168.1.1` | `192.168.1.1` | Servers, workstations, phones, ISP AP WiFi |
| iot | `vlan20` | `192.168.20.0/24` | `192.168.20.1` | `192.168.20.1` | AC1750 OpenWrt AP, smart plugs, Alexa, humidifier |
| media | `enp3s0` | `192.168.30.0/24` | `192.168.30.1` | `192.168.30.1` | PS5, Nintendo Switch, Mi Box, Roku TV |
| work | `vlan40` | `192.168.40.0/24` | `192.168.40.1` | `1.1.1.1` | Fully isolated work devices (office switch port 7) |

#### Office Switch — TL-SG108E #1 (`192.168.1.111`)

| Port | Device | PVID | Tagged VLANs |
|------|--------|------|-------------|
| 1 | Router `enp2s0` (uplink) | 1 | 10, 20, 40 |
| 2 | AC1750 OpenWrt (IoT AP) | 20 | — |
| 3–6, 8 | Wired trusted devices | 10 | — |
| 7 | Work port | 40 | — |

#### Living Room Switch — TL-SG108E #2 (`192.168.30.112`)

No VLAN configuration needed — all ports untagged, plain L2 switch.  
Router `enp3s0` plugged into any port; PS5, TV, Roku, Mi Box in remaining ports.  
Management IP is `192.168.30.112` — reachable from media segment only (via `enp3s0`).

#### Firewall Policy (nftables)

| Source | Destination | Allowed |
|--------|-------------|---------|
| trusted | iot | all |
| trusted | media | all |
| trusted | work | deny |
| iot | trusted | tcp 8123 (Home Assistant) |
| iot | media | tcp 8060 (Roku ECP) |
| media | trusted | tcp 8096,8920 (Jellyfin), tcp 9292 (Audiobookshelf), tcp 80,443 (Traefik), udp 1900,7359 (SSDP/DLNA), tcp 2049 (NFS) |
| work | * | deny |
| * | wan | allow (masquerade NAT) |

#### Services

- **Unbound** — recursive DNS resolver; NextDNS DoT upstream (profile `nextdns0`); split DNS `*.example.com` → homeserver; listens on trusted/iot/media gateway IPs
- **Kea DHCPv4** — static MAC reservations on all 4 zones; control socket at `/run/kea/kea-dhcp4.socket`
- **Avahi reflector** — mDNS proxy between trusted/iot/media (Chromecast, AirPlay, Roku discovery)
- **Tailscale** — headless auth via sops; advertises media VLAN `192.168.30.0/24`; login server `https://hs.example.com`

#### Monitoring (exporters, scraped by homeserver Prometheus via tailnet)

| Exporter | Port | Metrics |
|----------|------|---------|
| node_exporter | 9100 | CPU, RAM, network, conntrack, ethtool, nftables counters |
| unbound_exporter | 9167 | DNS cache hit rate, query latency, SERVFAIL rate |
| kea_exporter | 9547 | DHCP lease utilization per subnet |

Logs shipped to homeserver Loki via Alloy.  
Grafana dashboards: `router-overview`, `router-unbound`, `router-kea`.

#### Networking

- SSH on port 22; restricted by nftables to trusted zone + Tailscale only
- systemd-networkd; 802.1Q VLANs on office trunk `enp2s0`; media + AP as plain physical ports

See [router-installation.md](router-installation.md) for installation steps.

---

### homeserver

**Role:** Primary home server — all services, monitoring, DNS, VPN hub  
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

#### CPU / Scheduling

**Do not add `isolcpus`/`nohz_full`/`rcu_nocbs` kernel params without pinning a specific workload to the isolated cores.** They shipped in the original hardware-configuration (undocumented, no service ever used the isolated range) and silently parked all real work onto CPU0 — `mpstat` showed 0.00% usr on cores 1-7 despite services having full `0-7` affinity masks, because isolated CPUs are excluded from the default SMP load-balancing domain even though the affinity mask still permits them. Removed 2026-08-11; required a reboot (`nixos-rebuild boot`, not `switch`) since it's a boot param, not live-switchable.

**Scheduler:** `services.scx` — `scx_lavd --autopilot` (CPU: `i7-9700T`, homogeneous 8-core, no P/E-core split). Chosen 2026-08-11 after A/B testing `default`/`bpfland`/`lavd`/`flow`/`rusty`/`tickless` under a real software `libx265` transcode + `schbench` wakeup-latency load (post-isolcpus-fix): `lavd` matched top throughput (22.32 fps vs 21.80 `default`) and won typical-case latency by two orders of magnitude (90th percentile 16µs vs ~1000µs for `bpfland`/`default`), at the cost of a longer but still sub-8ms worst-case tail vs `bpfland`. `tickless` (the scheduler's own stated "server-oriented" pick) underperformed `default` in several percentiles without `nohz_full` and is explicitly marked "not recommended for production use" upstream — dropped. `--autopilot` (not `--performance`) so the box powers down when idle overnight and ramps only under real transcode load.

---

### desktop

**Role:** Primary workstation — Niri WM, gaming, dev tools  
**LAN IP:** `192.168.1.118` (ethernet) / `192.168.1.239` (WiFi)  
**GPU:** NVIDIA RTX 3050 8GB  
**CPU:** Ryzen 7000 series (Zen 4)  
**RAM:** 60 GB

#### Storage (Btrfs + Impermanence)

Disk: Samsung SSD 970 EVO Plus 1TB NVMe (`nvme-Samsung_SSD_970_EVO_Plus_1TB_S6S1NS0W101791N`). GPT: 2GB EFI + Btrfs remainder (label `nixos`).

| Subvolume | Mount              | Notes                                      |
|-----------|--------------------|--------------------------------------------|
| `/root`   | `/`                | Ephemeral — wiped on every boot via initrd |
| `/nix`    | `/nix`             | Persistent, `nodatacow`                    |
| `/persist`| `/persist`         | Persistent state (bind-mounted by impermanence) |
| `/log`    | `/var/log`         | Persistent logs                            |
| `/home`   | `/home`            | Persistent home                            |
| `/games`  | `/home/games`      | Steam library, large game files            |
| `/vms`    | `/var/lib/libvirt` | VM/container storage                       |

Root subvolume is deleted and recreated on every boot (`boot.initrd.postResumeCommands`). Persistent state lives in `/persist` and is bind-mounted by the `impermanence` NixOS module. Age keys, SSH host keys, tailscale state, NetworkManager connections, and user dotfiles are persisted.

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

#### CPU / Scheduling

`services.scx` — `scx_lavd --performance`. Chosen 2026-08-11 after A/B testing `bpfland`/`lavd`/`flow`/`rusty` via `stress-ng` + `schbench` wakeup-latency under CPU saturation (simulating a background `nix build` while gaming): `bpfland` and `lavd` tied for best, `rusty` had a 32ms worst-case outlier despite good median (dropped), `flow`'s median (1ms) was too high for interactive use. `lavd` edged out on total wakeup throughput and 99th percentile. `--performance` (not `--autopilot`) since this is an always-plugged-in desktop where max responsiveness is preferred over idle power saving.

---

### matebook

**Role:** Laptop — portable workstation  
**WiFi IP:** `192.168.1.132`

#### Storage

Disk: WD PC SN730 512GB NVMe (`nvme-WDC_PC_SN730_SDBPNTY-512G-1027_20230H445703`). GPT: 2GB EFI + **ext4** root (no ZFS). 16GB swapfile (`/swapfile`, TRIM-enabled) for hibernation support.

- Niri WM + noctalia-shell
- Nix daemon: **determinate** (vs lix on desktop/homeserver)
- Tailscale client with magic rollback enabled for remote deploys

#### CPU / Scheduling

`services.scx` — `scx_lavd --autopilot` (same scheduler choice as desktop, see its CPU/Scheduling section for the A/B test results). `--autopilot` instead of `--performance` here since it's battery-powered — lets LAVD's Core Compaction drop idle cores into deeper C-states when unplugged.

---

### gcp-relay

**Role:** GCP e2-micro — VPN control plane + DERP relay  
**Public IP:** `203.0.113.1`  
**Region:** GCP US Central (Iowa)

- **Headscale** coordination server: `https://hs.example.com` (port 8080 behind Caddy)
- **DERP** relay: region ID 901, `gcp-us-central1`, STUN on `0.0.0.0:3478`
- **Caddy** TLS termination (replaces Traefik for this host)
- **CrowdSec** nftables bouncer: remote LAPI via Tailscale pointing to homeserver
- **fail2ban**: SSH jail, incremental bans up to 168h
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

Known static Tailscale IPs (headscale has no declarative per-node static IP — assigned sequentially in its sqlite DB; pinned here by manual `UPDATE nodes SET ipv4=...` after registration):

| Host | Tailscale IP |
|------|---------------|
| desktop | `100.64.0.1` |
| homeserver | `100.64.0.3` |
| matebook | `100.64.0.4` |
| gcp-relay | `100.64.0.5` |

SSH config uses MagicDNS hostnames (`homeserver.ts.example.com`, `matebook.ts.example.com`, `gcp-relay.ts.example.com`) so SSH works from any network without hardcoded LAN IPs. Operator mode enabled on desktop + matebook (`extraSetFlags = ["--operator=zeev"]`) so `tailscale file cp` works without sudo.

### Unbound (recursive DNS)

On homeserver, listening on Tailscale + LAN interfaces. Forwards to NextDNS profile `nextdns0` with DNSSEC validation. Desktop and matebook use homeserver as resolver.

`example.com` is a `redirect` local-zone (answers homeserver's IPs for the whole zone). `ts.example.com` is carved out as `transparent` and forwarded to the Tailscale stub resolver (`100.100.100.100`), so individual per-node MagicDNS names (e.g. `matebook.ts.example.com`) resolve to their actual current Tailscale IP instead of being swallowed by the redirect.

### CrowdSec

- **homeserver**: LAPI at `127.0.0.1:8088`; Traefik bouncer (stream mode); collections: `linux`, `sshd`, `traefik`
- **gcp-relay**: nftables bouncer; remote LAPI via Tailscale pointing to homeserver
- Whitelists: Tailscale CGNAT `100.64.0.0/10`, LAN `192.168.1.0/24`, Cloudflare IPs

### Cloudflared

Cloudflare Tunnel for select services (configured in `modules/networking/cloudflared/`). Tunnel config rendered by sops template at runtime.

### NFS

NFS server on homeserver (`modules/networking/nfs/`); NFS client on desktop (`modules/networking/nfs-client/`).

| Client subnet | Access | Notes |
|---------------|--------|-------|
| `192.168.1.0/24` (trusted) | rw, no_root_squash | Desktop, matebook, servers |
| `100.64.0.0/10` (tailscale) | rw, no_root_squash | Remote access via tailnet |
| `192.168.30.0/24` (media) | ro, root_squash | Read-only; router forwards tcp/2049 media→trusted |

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
| Sonarr          | 8990  | `sonarr.example.com`         | TV — OCI container                 |
| Radarr          | 7878  | `radarr.example.com`         | Movies — OCI container             |
| Prowlarr        | 9696  | `prowlarr.example.com`       | Indexer — OCI container            |
| Bazarr          | 6767  | `bazarr.example.com`         | Subtitles — OCI container          |
| Lidarr          | 8686  | `lidarr.example.com`         | Music                              |
| LazyLibrarian   | 5299  | `lazylibrarian.example.com`  | Books — ephraim-nur overlay        |
| Kapowarr        | 5656  | `kapowarr.example.com`       | Comics                             |
| Seerr           | 5055  | `seerr.example.com`          | Request management — OCI container |
| Audiobookshelf  | 9292  | `audiobookshelf.example.com` | Audiobooks                         |
| Recyclarr       | —     | (no UI)                       | Auto-sync quality profiles to *arr |
| Byparr          | 8191  | (internal only)               | Cloudflare bypass for Prowlarr — FlareSolverr-compatible, OCI container |
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
router exporters (tailnet)  │
                            │
Systemd journal ────────────┤──► Alloy ──► Loki :3100
Traefik access.log ─────────┘
```

- **Prometheus** scrape targets: homeserver, desktop, matebook, gcp-relay, router node exporters; NUT; Traefik; CrowdSec; Prometheus self; router unbound + kea
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
  tailscale-router.yaml

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
