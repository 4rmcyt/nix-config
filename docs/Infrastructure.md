# Infrastructure

Domain: `<domain>`  
Timezone: `America/Edmonton`  
Tailnet login server: `https://hs.<domain>` (self-hosted Headscale)

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
| `enp5s0` | WAN | ISP router (DHCP) |
| `enp4s0` | Office trunk (802.1Q) | TL-SG108E #1 `192.168.1.111` — tagged vlan10 + vlan20 + vlan40 |
| `enp3s0` | Media (physical, no VLAN), `192.168.30.1/24` | TL-SG108E #2 `192.168.30.112` — all ports untagged |
| `enp2s0` | Trusted AP (physical), `192.168.1.1/24` | ISP AP (trusted WiFi) |

Interface names are set in `hosts/nixos/router/networking.nix` (`wanInterface`/`trunkInterface`/`mediaInterface`/`apInterface`) and matched again by name in `firewall.nix`'s nftables ruleset — verify with `ip link` on hardware and keep both files in sync.

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
| 1 | Router `enp4s0` (uplink) | 1 | 10, 20, 40 |
| 3–6 | Wired trusted devices | 10 | — |
| 7 | Work port | 40 | — |
| 8 | AC1750 OpenWrt (IoT AP) | 20 | — |

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

- **Unbound** — recursive DNS resolver; NextDNS DoT upstream (profile `<nextdns-profile>`); split DNS `*.<domain>` → homeserver; listens on trusted/iot/media gateway IPs
- **Kea DHCPv4** — static MAC reservations on all 4 zones; control socket at `/run/kea/kea-dhcp4.socket`
- **Avahi reflector** — mDNS proxy between trusted/iot/media (Chromecast, AirPlay, Roku discovery)
- **Tailscale** — headless auth via sops; advertises media VLAN `192.168.30.0/24`; login server `https://hs.<domain>`

#### Monitoring (exporters, scraped by homeserver Prometheus via tailnet)

| Exporter | Port | Metrics |
|----------|------|---------|
| node_exporter | 9100 | CPU, RAM, network, conntrack, ethtool, nftables counters |
| unbound_exporter | 9167 | DNS cache hit rate, query latency, SERVFAIL rate |
| kea_exporter | 9547 | DHCP lease utilization per subnet |

Logs shipped to homeserver Loki via Alloy.  
Grafana dashboards: `router-overview`, `router-unbound`, `router-kea`.

#### Networking

- SSH on port 22; sshd listens on all interfaces but the nftables input chain only permits tcp/22 from `vlan10` and `tailscale0`
- systemd-networkd; 802.1Q VLANs on office trunk `enp4s0`; media (`enp3s0`) + AP (`enp2s0`) as plain physical ports; `networking.firewall.enable = false` — nftables ruleset in `firewall.nix` is authoritative

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
- Unbound DNS resolver: interfaces `tailscale0`, `enp0s31f6`; NextDNS profile `<nextdns-profile>`
- Tailscale with DNSSEC: NextDNS upstream, split DNS for `<domain>` → homeserver

#### Nix Build

- `cores = 4`, `max-jobs = 4`, `big-parallel` feature enabled
- `nix-builder` system user accepts remote builds from desktop

#### CPU / Scheduling

**Do not add `isolcpus`/`nohz_full`/`rcu_nocbs` kernel params without pinning a specific workload to the isolated cores.** They shipped in the original hardware-configuration (undocumented, no service ever used the isolated range) and silently parked all real work onto CPU0 — `mpstat` showed 0.00% usr on cores 1-7 despite services having full `0-7` affinity masks, because isolated CPUs are excluded from the default SMP load-balancing domain even though the affinity mask still permits them. Removed 2026-08-11; required a reboot (`nixos-rebuild boot`, not `switch`) since it's a boot param, not live-switchable.

**Scheduler:** `services.scx` — `scx_lavd --autopilot` (CPU: `i7-9700T`, homogeneous 8-core, no P/E-core split). Chosen 2026-08-11 after A/B testing `default`/`bpfland`/`lavd`/`flow`/`rusty`/`tickless` under a real software `libx265` transcode + `schbench` wakeup-latency load (post-isolcpus-fix): `lavd` matched top throughput (22.32 fps vs 21.80 `default`) and won typical-case latency by two orders of magnitude (90th percentile 16µs vs ~1000µs for `bpfland`/`default`), at the cost of a longer but still sub-8ms worst-case tail vs `bpfland`. `tickless` (the scheduler's own stated "server-oriented" pick) underperformed `default` in several percentiles without `nohz_full` and is explicitly marked "not recommended for production use" upstream — dropped. `--autopilot` (not `--performance`) so the box powers down when idle overnight and ramps only under real transcode load.

---

### desktop

**Role:** Primary workstation — mango WM, gaming, dev tools, local LLM, libvirt  
**GPU:** NVIDIA  
**CPU:** AMD Zen 4  
(LAN IPs / RAM: see `inputs.private` topology — not tracked in this repo)

#### Storage (Btrfs)

Disko config in `modules/disko/desktop/`. GPT: `/boot` ESP + Btrfs remainder (label `nixos`), all subvolumes `compress=zstd:1,noatime,ssd,discard=async,space_cache=v2`.

| Subvolume | Mount              | Notes                                 |
|-----------|--------------------|---------------------------------------|
| `/root`   | `/`                | Persistent (not ephemeral)            |
| `/nix`    | `/nix`             | `nodatacow`                           |
| `/log`    | `/var/log`         | Logs                                  |
| `/home`   | `/home`            | Home                                  |
| `/games`  | `/home/games`      | Steam library, large game files       |
| `/vms`    | `/var/lib/libvirt` | libvirt VM storage                    |

`inputs.impermanence` is declared in `flake.nix` but **not imported by any host** — there is no ephemeral-root / `/persist` setup on desktop. `btrfs.autoScrub` runs on `/`.

#### Desktop Stack

- **WM:** mango (`inputs.mango` `wl-only` branch, Vulkan renderer for HDR; nixpkgs `programs.mango` module + flake package)
- **DM:** greetd, execs `env WLR_RENDERER=vulkan mango` directly for `zeev`
- **Shell:** noctalia v5 (native C++ bar/shell, no Quickshell)
- **Theming:** noctalia dynamic colors (Stylix wired but currently disabled)
- **Portal:** `modules/xdg` (portal-gnome + portal-gtk); gnome-keyring for secrets
- Ran Hyprland until 2026-08-22, then fully migrated to mango

#### Nix Build

- `cores = 0` (all), `max-jobs = auto`, `big-parallel + kvm` features
- Sends builds to homeserver via `nix-builder` user over SSH

#### CPU / Scheduling

`services.scx-loader` (DBus-managed, hot-swappable) — daily driver `scx_lavd` in `Auto` mode (`--autopilot`, Core Compaction on).

Superseded `scx_lavd --performance` (chosen 2026-08-11 after A/B testing `bpfland`/`lavd`/`flow`/`rusty` via `stress-ng` + `schbench` wakeup-latency under CPU saturation: `bpfland` and `lavd` tied for best, `rusty` had a 32ms worst-case outlier, `flow`'s 1ms median was too high; `lavd` edged out on total wakeup throughput and 99th percentile). `--performance` disables Core Compaction and pins all cores to max frequency; under game + GPU frequency/thermal churn it self-unloaded with "runnable task stall" and froze the desktop 30-40s. Reverted to `--autopilot` (as homeserver runs), moved to `scx-loader` for runtime switching.

Game launch/exit swap the scheduler via gamemode custom hooks (`modules/gaming/default.nix`): on launch → `scx_bpfland -m all` (`gaming` mode; cache-topology-aware, A/B-tied with lavd, no cpufreq forcing); on exit → back to `scx_lavd` auto. A polkit rule lets the user session call `org.scx.loader.manage-schedulers` without a password prompt.

---

### matebook

**Role:** Laptop — portable workstation  
**WiFi IP:** `192.168.1.132`

#### Storage

Disk: NVMe, GPT: ESP + **ext4** root (no ZFS). Swapfile (`/swapfile`, TRIM-enabled) on the ext4 root for hibernation; `resume_offset` kernel param must be regenerated whenever the swapfile is recreated.

- **niri** WM + noctalia v5; greetd runs `niri-session` for `zeev`
- Boot: **Limine** bootloader (`boot.loader.limine`, `secureBoot.enable = true`, custom wallpaper), systemd-boot disabled
- Nix daemon: **lix** (same as desktop/homeserver/router)
- `services.tailscale` with `authKeyFile` from sops, Headscale login server
- Power: `auto-cpufreq` (powersave on battery / performance on charger), `power-profiles-daemon` disabled, lid → suspend-then-hibernate

#### CPU / Scheduling

`services.scx` — `scx_lavd --autopilot` (same scheduler choice as desktop, see its CPU/Scheduling section for the A/B test results). `--autopilot` instead of `--performance` here since it's battery-powered — lets LAVD's Core Compaction drop idle cores into deeper C-states when unplugged.

---

### gcp-relay

**Role:** GCP e2-micro — VPN control plane + DERP relay  
**Public IP:** `<gcp-relay-ip>`  
**Region:** GCP US Central (Iowa)

- **Headscale** coordination server: `https://hs.<domain>` (port 8080 behind Caddy)
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
- `komga`: uses `komga-headers` instead of `security-headers` — allows the komf webui to iframe Komga (`frame-ancestors https://komf.<domain>`) and call its API cross-origin (CORS with credentials)
- `komf`: uses `komf-headers` — CORS `Access-Control-Allow-Origin: *` (komf is Tailscale/LAN-only and unauthenticated, so the komf browser extension can reach it)
- Public-facing `hass`: additionally `rate-limit` + `geoblock` (CA/US only)
- Metrics endpoint on `127.0.0.1:8080`; internal API on `127.0.0.1:8083` (homepage widget)
- Access logs: JSON, errors + slow requests only, 14-day rotation

### Headscale (Tailnet control plane)

Running on GCP relay. Split DNS: `<domain>` → `100.64.0.3` (homeserver Tailscale IP).  
Magic DNS base domain: `ts.<domain>`. DERP: GCP US Central + Tailscale default map.

Known static Tailscale IPs (headscale has no declarative per-node static IP — assigned sequentially in its sqlite DB; pinned here by manual `UPDATE nodes SET ipv4=...` after registration):

| Host | Tailscale IP |
|------|---------------|
| desktop | `100.64.0.1` |
| homeserver | `100.64.0.3` |
| matebook | `100.64.0.4` |
| gcp-relay | `100.64.0.5` |

SSH config uses MagicDNS hostnames (`homeserver.ts.<domain>`, `matebook.ts.<domain>`, `gcp-relay.ts.<domain>`) so SSH works from any network without hardcoded LAN IPs. Operator mode enabled on desktop + matebook (`extraSetFlags = ["--operator=zeev"]`) so `tailscale file cp` works without sudo.

### Unbound (recursive DNS)

On homeserver, listening on Tailscale + LAN interfaces. Forwards to NextDNS profile `<nextdns-profile>` with DNSSEC validation. Desktop and matebook use homeserver as resolver.

`<domain>` is a `redirect` local-zone (answers homeserver's IPs for the whole zone). `ts.<domain>` is carved out as `transparent` and forwarded to the Tailscale stub resolver (`100.100.100.100`), so individual per-node MagicDNS names (e.g. `matebook.ts.<domain>`) resolve to their actual current Tailscale IP instead of being swallowed by the redirect.

### CrowdSec

- **homeserver**: LAPI at `127.0.0.1:8088`; Traefik bouncer (stream mode); collections: `linux`, `sshd`, `traefik`
- **gcp-relay**: nftables bouncer; remote LAPI via Tailscale pointing to homeserver
- Whitelists: Tailscale CGNAT `100.64.0.0/10`, LAN `192.168.1.0/24`, Cloudflare IPs

### Cloudflared

Cloudflare Tunnel for select services (configured in `modules/networking/cloudflared/`), via nixpkgs' native `services.cloudflared.tunnels` module (fully declarative — DNS routes are created by cloudflared itself using an account-level `certificateFile`, no manual dashboard steps).

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

Most services are behind Traefik at `*.<domain>`. A subset is additionally exposed via **Cloudflare Tunnel** (no open inbound ports required).

### Cloudflare Tunnel

Active tunnels (proxied through `localhost:443` → Traefik):

| Hostname                 | Purpose                      | Cloudflare Access |
|--------------------------|-------------------------------|-------------------|
| `hass.<domain>`      | Home Assistant (public)      | Yes (`owner-only` policy) |
| `livesync.<domain>`  | CouchDB / Obsidian LiveSync  | No |
| `cal.<domain>`       | Radicale CalDAV/CardDAV      | No |
| `ntfy.<domain>`      | Push notifications           | No |
| `jobko.<domain>`     | job-kombayn (web + API)      | No |
| `idm.<domain>`       | Kanidm SSO                   | Yes (`owner-only` policy) |

`hass` and `idm` additionally sit behind a Cloudflare Zero Trust Access application (email OTP gate, policy `owner-only` restricted to the owner's email) — configured in the Cloudflare dashboard (Access controls → Applications), not declarative in this repo, since nixpkgs' `services.cloudflared` has no Access support. This only affects requests that actually cross Cloudflare's edge; LAN/Tailscale clients resolve `*.<domain>` straight to the homeserver via the split-horizon Unbound config (`modules/networking/unbound/`) and never touch Access or the tunnel at all. Kanidm's own auth (username + WebAuthn/Yubikey) is unchanged and still required after Access.

Tunnel credentials in `secrets/cloudflare_tunnel_credentials.bin` (per-tunnel, scoped) + `secrets/cloudflare_tunnel_cert.pem` (account-level `cert.pem` from `cloudflared login`, needed so cloudflared can create the DNS routes itself). Tunnel UUID (`57a75d0b-ba3c-4b13-9e45-8854e13fc0fb`, name `homeserver-nix`) is hardcoded in the module — it's not sensitive on its own (publicly derivable from any `<uuid>.cfargotunnel.com` CNAME target) and has to be a literal Nix attribute name. This tunnel was created via CLI (`cloudflared tunnel create`), not the dashboard — dashboard-created tunnels are permanently remotely-managed and silently ignore any local `--config`/ingress, no matter what options are passed (confirmed via cloudflared GitHub issue #843 and live testing against the old `homeserver` dashboard tunnel, f7876e26-..., now retired).

### jobko.<domain> hardening

All configured via the Cloudflare dashboard/API (zone `<domain>`, Free plan) — not declarative, no nixpkgs module covers these:

- **Rate limiting rule** `jobko-auth-ratelimit` (Security rules → Rate limiting rules): blocks IPs exceeding 3 requests/10s (Free plan's max window) to `/api/auth/login` or `/api/auth/register`.
- **Schema validation**: job-kombayn's OpenAPI schema (exported via `python -m kombayn.export_openapi`, converted 3.1→3.0.3 since Cloudflare only accepts v3.0.x, `servers` added manually since FastAPI doesn't set it, `additionalProperties: false` added by hand to `LoginRequest`/`RegisterRequest`/`StatusUpdate`/`ProfileIn` since OpenAPI/FastAPI leaves it unset — i.e. extra fields allowed — by default) uploaded as `jobko-openapi.json`, zone-level `validation_default_mitigation_action: block`. Per-operation overrides must be `null` (inherit), not `none` — the dashboard's "Add schema and endpoints" wizard sets every operation to an explicit `none` override by default, silently defeating the zone-level action; cleared via `PATCH /zones/{id}/schema_validation/settings/operations` with each operation set to `{"mitigation_action": null}` (must be redone after any schema re-upload). `log` action requires a paid plan; Free only gets `none`/`block`. Confirmed live: a request missing the required `email` field, or one with a wrong-typed `email`/an extra body field, gets a 403 from Cloudflare's edge (not the origin) on `/api/auth/login`.
- **Bot Fight Mode** and **Leaked Credentials Detection** (Security → Settings): both enabled zone-wide.
- Cloudflare Access was deliberately **not** put in front of jobko (unlike hass/idm) — job-kombayn has multiple real users (profiles for `volodymyr-kondratenko` and `sofiia-rogatska`) and open self-service `/api/auth/register`; gating the whole app behind Access would need a bypass rule on the signup path plus app-level automation to add new signups' emails to the Access policy, which isn't built.

### Media

| Service         | Port  | URL                           | Notes                              |
|-----------------|-------|-------------------------------|------------------------------------|
| Jellyfin        | 8096  | `jellyfin.<domain>`       | `inputs.arr-packages` build         |
| qBittorrent     | 8081  | `qb.<domain>`             | via nixarr                          |
| Sonarr          | 8990  | `sonarr.<domain>`         | TV — native `services.sonarr`, Postgres backend |
| Radarr          | 7878  | `radarr.<domain>`         | Movies — native `services.radarr`, Postgres backend |
| Prowlarr        | 9696  | `prowlarr.<domain>`       | Indexer — native `services.prowlarr`, Postgres backend |
| Bazarr          | 6767  | `bazarr.<domain>`         | Subtitles — native `services.bazarr`, Postgres backend |
| Lidarr          | 8686  | `lidarr.<domain>`         | Music                               |
| LazyLibrarian   | 5299  | `lazylibrarian.<domain>`  | Books — OCI container               |
| Kapowarr        | 5656  | `kapowarr.<domain>`       | Comics & manga — OCI container. DDL temp folder `/app/temp_downloads` → `/data/Downloads/kapowarr`; library roots `/comics`, `/manga`. qBittorrent category `kapowarr` saves to the same path (Remote Path Mapping `/data/Downloads/kapowarr`→`/app/temp_downloads` in the web UI). ComicVine key set in web UI. |
| Seerr           | 5055  | `seerr.<domain>`          | Request management — OCI container |
| Audiobookshelf  | 9292  | `audiobookshelf.<domain>` | Audiobooks                         |
| Recyclarr       | —     | (no UI)                       | Auto-sync quality profiles to *arr |
| Byparr          | 8191  | (internal only)               | Cloudflare bypass for Prowlarr — FlareSolverr-compatible, OCI container |
| Dispatcharr     | 9191  | `dispatcharr.<domain>`    | Stream dispatch — OCI container    |

### Reading / Library

| Service   | Port  | URL                      | Notes             |
|-----------|-------|--------------------------|-------------------|
| Komga     | 8087  | `komga.<domain>`     |                   |
| Komf      | 8085  | `komf.<domain>`      |                   |
| Miniflux  | 8086  | `miniflux.<domain>`  |                   |

### Identity / SSO

| Service  | Port  | URL                    | Notes                                                     |
|----------|-------|------------------------|-----------------------------------------------------------|
| Kanidm   | 3013  | `idm.<domain>`     | OIDC provider for Grafana, Miniflux, Jellyfin, Audiobookshelf, Headscale. Self-signed TLS internally, Traefik terminates externally via `insecureSkipVerify`. Provisioned declaratively via sops secrets. |

### Productivity / Home

| Service        | Port  | URL                        | Notes                         |
|----------------|-------|----------------------------|-------------------------------|
| Home Assistant | 8123  | `hass.<domain>`        | Podman OCI container; Alexa Smart Home; WoL for desktop; geoblock + rate-limit |
| Homepage       | 8082  | `home.<domain>`        | Dashboard (pinned v1.13.1 overlay) |
| Radicale       | 5232  | `cal.<domain>`         | CalDAV/CardDAV                |
| ntfy           | 9991  | `ntfy.<domain>`        | Push notifications            |
| Microbin       | 8069  | `microbin.<domain>`    | Paste bin                     |
| Atuin server   | 8881  | `atuin.<domain>`       | Shell history sync            |
| CouchDB        | 5984  | `livesync.<domain>`    | Obsidian LiveSync backend     |

### AI / Local LLM

| Service   | Notes                                                                    |
|-----------|--------------------------------------------------------------------------|
| llama-cpp | Desktop only (`modules/TUI/ai-tools/llama-cpp`). CPU inference server, on-demand (no `WantedBy`), auto-unloads after 5 min idle. Model: `Qwen2.5-32B-Instruct-Q4_K_M` (bartowski GGUF), used for story.json generation. A lighter `cpu.nix` variant also exists. |

---

## Monitoring Stack (homeserver)

```
node_exporter (all hosts) ──┐
NUT exporter                ├──► Prometheus :9090 ──► Grafana :3003  ──► grafana.<domain>
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
| CouchDB    | Obsidian LiveSync backend (`livesync.<domain>`) |

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
