# Infrastructure

Domain: `<domain>`  
Timezone: `America/Edmonton`  
Tailnet login server: `https://hs.<domain>` (self-hosted Headscale)

---

## Hosts

### homeserver

**Role:** Primary home server — all services, monitoring, DNS, VPN hub  
**LAN IP:** static in the trusted VLAN (`my.network.hosts.homeserver_lan`)  
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
- `/etc/hosts`: `idm.<domain>` → `127.0.0.1`, so server-side OIDC (Grafana, Miniflux) reaches Kanidm via local Caddy without MagicDNS

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
- **Theming:** noctalia dynamic colors
- **Portal:** handled by nixpkgs' own `programs.mango` module (portal-wlr + portal-gtk, gnome-keyring for secrets) — no repo-local xdg module
- Ran Hyprland until 2026-08-22, then fully migrated to mango

#### Networking

Desktop runs Tailscale with `--accept-routes`, so homeserver's advertised `192.168.1.0/24` lands in table 52 (`ip rule 5270`). Without an override, all desktop→LAN traffic (router, printer, homeserver by LAN IP) hairpins through homeserver over `tailscale0`, and replies to LAN-originated connections leave via `tailscale0` with a LAN source and get dropped.

`modules/networking/lan-routing` (unit `lan-route`) adds `ip rule to <trusted> lookup main priority 5200`, ahead of Tailscale's rules: trusted-LAN traffic stays on the wire, so it survives homeserver, `tailscaled`, router or internet loss (NUT relies on this). Tailnet `100.x` traffic is unaffected.

#### Nix Build

- `cores = 0` (all), `max-jobs = auto`, `big-parallel + kvm` features
- Sends builds to homeserver via `nix-builder` user over SSH

#### CPU / Scheduling

`services.scx-loader` (DBus-managed, hot-swappable) — daily driver `scx_lavd` in `Auto` mode (`--autopilot`, Core Compaction on).

Superseded `scx_lavd --performance` (chosen 2026-08-11 after A/B testing `bpfland`/`lavd`/`flow`/`rusty` via `stress-ng` + `schbench` wakeup-latency under CPU saturation: `bpfland` and `lavd` tied for best, `rusty` had a 32ms worst-case outlier, `flow`'s 1ms median was too high; `lavd` edged out on total wakeup throughput and 99th percentile). `--performance` disables Core Compaction and pins all cores to max frequency; under game + GPU frequency/thermal churn it self-unloaded with "runnable task stall" and froze the desktop 30-40s. Reverted to `--autopilot` (as homeserver runs), moved to `scx-loader` for runtime switching.

Game launch/exit swap the scheduler via gamemode custom hooks (`modules/gaming/default.nix`): on launch → `scx_bpfland -m all` (`gaming` mode; cache-topology-aware, A/B-tied with lavd, no cpufreq forcing); on exit → back to `scx_lavd` auto. A polkit rule lets the user session call `org.scx.loader.manage-schedulers` without a password prompt.

---

### matebook

**Status: decommissioned — no longer in use.**

**Role:** Laptop — portable workstation  
**WiFi IP:** static in the trusted VLAN (`my.network.hosts.matebook_wifi`)

#### Storage

Disk: NVMe, GPT: ESP + **ext4** root (no ZFS). Swapfile (`/swapfile`, TRIM-enabled) on the ext4 root for hibernation; `resume_offset` kernel param must be regenerated whenever the swapfile is recreated.

- **niri** WM + noctalia v5; greetd runs `niri-session` for `zeev`
- Boot: **Limine** bootloader (`boot.loader.limine`, `secureBoot.enable = true`, custom wallpaper), systemd-boot disabled
- Nix daemon: **lix** (same as desktop/homeserver)
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
- **Caddy** TLS termination
- **CrowdSec** nftables bouncer: remote LAPI via Tailscale pointing to homeserver
- **SSH**: tailnet only (port 22 closed publicly); fallback via GCE Serial Console
- **Shell**: zsh + starship via NixOS options (`hosts/nixos/gcp-relay/shell.nix`), no Home Manager
- Root disk: 10 GB, zram swap, journal capped at 500 MB / 14 days
- node_exporter scraped by homeserver Prometheus

---

## Networking Stack (homeserver)

### Firewall exposure (homeserver)

Global (all interfaces): 2222 (SSH), 2049 (NFS, exports restrict to trusted/media). Caddy 80/443 (+ UDP 443): every interface except the LAN NIC, where IPv4 only — the ISP router (Telus NH20T) passes inbound IPv6 :443 to homeserver even on firewall level Low.
Per interface: LAN NIC — 53, Jellyfin 8096/8920 + UDP 1900/7359 (TVs/DLNA by IP), VictoriaLogs ingest 9429 and NUT 3493 from desktop's IPs only (`extraInputRules`); `podman0` — Prowlarr, Jellyfin, Radarr, Sonarr (containers via `host.containers.internal`); `tailscale0` and `cni0` — see `hosts/nixos/homeserver/default.nix`.
Every other service UI is loopback/Caddy-only; container ports are published on `127.0.0.1` only (published ports are DNAT'd past the NixOS firewall, so a LAN-IP publish would bypass it).

### Caddy (reverse proxy)

`modules/networking/caddy-homeserver`, option `my.caddyHomeserver.enable`. Enabled on homeserver.

- Plugins via `pkgs.caddy.withPlugins`: `caddy-dns/cloudflare`, `hslatman/caddy-crowdsec-bouncer`, `porech/caddy-maxmind-geolocation`, `mholt/caddy-ratelimit`. Tags + per-host hashes in `modules/networking/caddy-plugins.json` (shared with gcp-relay), refreshed by `just caddy-update` (part of `just update`)
- One wildcard `*.<domain>` cert (DNS-01); per-site blocks reuse it (Caddy ≥2.10), unknown subdomains → 404
- Sites: media/*arr, reading, home & personal, `kanidm` (`idm.`), `jobko` (`/api*` split) and k3s `argocd.<domain>` → NodePort `30080` on loopback (HTTPS upstream; site LAN/Tailscale only)
- Per-site `route`: `crowdsec` → `appsec` (CrowdSec WAF, tunnel hostnames only: hass, livesync, cal, ntfy, jobko, idm; `appsec_fail_open`) → (`hass`: geoblock CA/US via `/var/lib/geoip/city.mmdb` + `rate_limit` 100/s) → headers (security / komga / komf CORS) → `encode zstd gzip` (not ntfy — streaming) → `reverse_proxy`
- HTTP/3: UDP 443 open in the homeserver firewall
- Guest listener on `:8443` (`ports.caddy-guest`, firewall: `tailscale0` only): only `guestSites` (jellyfin, audiobookshelf, komga, seerr) exist there, same per-site route as `:443`. Headscale's `guest@` grant allows only this port + 53, so guest devices can't reach any other site. `http://` redirects still go to 443 (Caddy prefers the HTTPS port when a host is on several)
- `geoip-update` (monthly) runs `systemctl try-reload-or-restart caddy` afterwards: the maxmind matcher keeps the mmdb open until reload
- `trusted_proxies`: Cloudflare + loopback (cloudflared); client IP from `Cf-Connecting-IP`/`X-Forwarded-For`
- Access logs JSON → journal → CrowdSec (`my.crowdsec.caddy`) + journal-upload → VictoriaLogs
- Admin API + `/metrics` on `localhost:2019`: Prometheus job `caddy`, homepage `caddy` widget, Grafana dashboard `caddy-homeserver` (no web UI)

### ua-exit (Tailscale exit node via Ukraine)

`modules/networking/ua-exit`, `my.uaExit.enable` (homeserver). VPN-Confinement netns `ua` (`192.168.16.0/24`, `fd93:9701:1d01::/64`) with the ClearVPN Ukraine WireGuard config (`secrets/wg-ua.conf`, sops binary). A second `tailscaled` (`tailscaled-ua.service`, state `/var/lib/tailscale-ua`, socket `/run/tailscale-ua/tailscaled.sock`) runs inside it as tailnet node `ua-exit` advertising an exit node; CLI wrapper `tailscale-ua`. Select it on a client when Ukrainian sites are needed. The host's own tailscaled is unaffected.

### Headscale (Tailnet control plane)

Running on GCP relay. Split DNS: `<domain>` → homeserver's Tailscale IP.  
Magic DNS base domain: `ts.<domain>`. DERP: GCP US Central + Tailscale default map.

Each node is pinned to a fixed address in the `100.64.0.0/10` CGNAT range via a
manual `UPDATE nodes SET ipv4=...` in headscale's sqlite DB after registration
(headscale has no declarative per-node static IP — it otherwise assigns them
sequentially).

**Policy (default-deny grants)** — `modules/networking/headscale/policy.nix`, rendered to a JSON file (`settings.policy.mode = "file"`). Host aliases come from `my.network.hosts.*_ts` (hence the pinned IPs above) plus `lan` = `subnets.trusted`:

| Source | Destination | Ports |
|--------|-------------|-------|
| desktop | `*`, `autogroup:internet` | all |
| s23plus, s23ultra | homeserver, desktop, `lan` (subnet route), `autogroup:internet` (exit nodes) | all |
| gcp-relay | homeserver | tcp crowdsec-lapi, tcp victorialogs-ingest 9429 (journal-upload), 53 (split DNS) |
| homeserver | gcp-relay | tcp node-exporter |
| homeserver | desktop | tcp 22 (nix-builder) |
| `guest@` (any device of headscale user `guest`) | homeserver | tcp caddy-guest (8443), 53 |

Not listed (router, matebook, ua-exit as a source) get nothing. `autogroup:internet` covers every approved exit node (homeserver, ua-exit). Route/exit-node approvals stay manual (no `autoApprovers`). A new node needs a pinned IP + `*_ts` option + a grant before it can talk to anything.

SSH config uses MagicDNS hostnames (`homeserver.ts.<domain>`, `matebook.ts.<domain>`, `gcp-relay.ts.<domain>`) so SSH works from any network without hardcoded LAN IPs. Operator mode enabled on desktop + matebook (`extraSetFlags = ["--operator=zeev"]`) so `tailscale file cp` works without sudo.

### Unbound (recursive DNS)

On homeserver, listening on Tailscale + LAN interfaces. Forwards to NextDNS profile `<nextdns-profile>` with DNSSEC validation. Clients reach it only through MagicDNS split DNS (`<domain>` → `homeserver_ts`); desktop/homeserver `resolved` itself uses MagicDNS on `tailscale0` plus global NextDNS DoT. The router's DHCP-provided NextDNS on `enp*` never answers (global `DNSOverTLS=true`). Low-level flows (NUT, Prometheus, log shipping, NFS, alerts) use IPs or `/etc/hosts`, not DNS.

`<domain>` is a `redirect` local-zone answering homeserver's IP for the whole zone, split by source via `access-control-view`: tailnet clients (`100.64.0.0/10`, i.e. everything arriving through MagicDNS split DNS) get the `tailnet` view → `homeserver_ts` only; everyone else gets the global zones → `homeserver_lan` only. The view repeats the `ts`/`hs`/`hp` carve-outs because view zones replace the global ones. `ts.<domain>` is carved out as `transparent` and forwarded to the Tailscale stub resolver (`100.100.100.100`), so individual per-node MagicDNS names (e.g. `matebook.ts.<domain>`) resolve to their actual current Tailscale IP instead of being swallowed by the redirect.

### CrowdSec

- **homeserver**: LAPI at `127.0.0.1:8088`; Caddy bouncer (stream mode); AppSec (WAF) component on `127.0.0.1:7422` (`my.crowdsec.appsec`, `appsec-default` config, `appsec-virtual-patching` + `appsec-generic-rules`); collections: `linux`, `sshd`, `caddy`
- Local Caddy log acquisition is `journalctl` with `labels.type: syslog`, not `caddy`: journalctl emits `Mon DD hh:mm:ss host caddy[pid]: {json}`, and only `syslog-logs` strips that prefix (sets `program=caddy`) so `caddy-logs` can parse the JSON. With `type: caddy` every line failed `UnmarshalJSON` (broken from the Caddy switch on 2026-10-04 until 2026-10-05). Bans use Caddy's `client_ip` (real client behind Cloudflare via `trusted_proxies`)
- **gcp-relay**: nftables bouncer; remote LAPI via Tailscale pointing to homeserver. Caddy access log → journal → journal-upload → VictoriaLogs → homeserver CrowdSec (`victorialogs` datasource in tail mode, `my.crowdsec.remoteCaddy`, query pinned to `remote_ip` = gcp-relay tailnet IP) — no agent on the relay
- Whitelists: Tailscale CGNAT `100.64.0.0/10`, LAN `192.168.1.0/24`, Cloudflare IPs

### Cloudflared

Cloudflare Tunnel for select services (configured in `modules/networking/cloudflared/`), via nixpkgs' native `services.cloudflared.tunnels` module (fully declarative — DNS routes are created by cloudflared itself using an account-level `certificateFile`, no manual dashboard steps).

### NFS

NFS server on homeserver (`modules/networking/nfs/`), **NFSv4-only** (`vers3=n`; rpcbind/rpc-statd masked, rpc.mountd has no network listeners — only tcp/2049; idmapd/mountd/nfsdcld sandboxed, no PrivateNetwork since `/proc/net/rpc` is per-netns); NFS client on desktop (`modules/networking/nfs-client/`).

| Client subnet | Access | Notes |
|---------------|--------|-------|
| `192.168.1.0/24` (trusted) | rw, no_root_squash | Desktop (over LAN via `lan-routing`, not tailnet). Only rw export: no tailnet (gcp-relay/phones) and no ISP-router `192.168.0.0/24` |
| `192.168.30.0/24` (media) | ro, root_squash | Read-only; gateway forwards tcp/2049 media→trusted |

### UPS (NUT)

NUT server on homeserver (`modules/networking/nut-server/`, upsmon `primary`); NUT client on desktop (`modules/networking/nut-client/`, own upsd user `upsmon-desktop` with `upsmon secondary` — can't request FSD; connects via `homeserver_lan`; kept off tailscale0 by desktop's `lan-routing` rule, see desktop → Networking; the LAN switch is on UPS power). Prometheus NUT exporter scrapes battery/load metrics. `upsd` and `upsmon` on homeserver run sandboxed (capability-bounded, `ProtectSystem`, syscall filter).

Graceful shutdown: each host runs `upssched` with an `ONBATT` timer cancelled on `ONLINE`; on expiry it runs `upsmon -c fsd`. Desktop (heavy load) fires at 30s and only shuts itself down (secondary FSD doesn't set FSD on upsd). Homeserver fires at 5 min (alone it lasts ~9 min to `LB`): sets FSD, waits up to `HOSTSYNC` (15s) for secondaries, then shuts down; `ups-killpower` runs `upsdrvctl shutdown` at the end so the UPS cycles and powers hosts back on when mains returns (needs BIOS "Restore on AC power loss = Power On"). UPS's own `LB` remains a fallback trigger. `upsdrv` has `TimeoutStopSec=10s`: `usbhid-ups` was seen hanging after SIGTERM during an FSD shutdown, stalling it 90s.

---

## Services (homeserver)

Most services are behind Caddy at `*.<domain>`. A subset is additionally exposed via **Cloudflare Tunnel** (no open inbound ports required).

### Cloudflare Tunnel

Active tunnels (proxied through `localhost:443` → Caddy):

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
- Cloudflare Access was deliberately **not** put in front of jobko (unlike hass/idm) — job-kombayn has multiple real users and open self-service `/api/auth/register`; gating the whole app behind Access would need a bypass rule on the signup path plus app-level automation to add new signups' emails to the Access policy, which isn't built.

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
| Byparr          | 8191  | (internal only)               | Cloudflare bypass for Prowlarr — FlareSolverr-compatible (GET only), OCI container on the podman bridge, published on 127.0.0.1 only |
| FlareSolverr    | 8193  | (internal only)               | POST-capable Cloudflare solver, native `services.flaresolverr` on 127.0.0.1 — Prowlarr proxy for RuTracker login only; `LOG_LEVEL=warning` (INFO logs POST bodies incl. passwords) |

### Reading / Library

| Service   | Port  | URL                      | Notes             |
|-----------|-------|--------------------------|-------------------|
| Komga     | 8087  | `komga.<domain>`     |                   |
| Komf      | 8085  | `komf.<domain>`      |                   |
| Miniflux  | 8086  | `miniflux.<domain>`  |                   |

### Identity / SSO

| Service  | Port  | URL                    | Notes                                                     |
|----------|-------|------------------------|-----------------------------------------------------------|
| Kanidm   | 3013  | `idm.<domain>`     | OIDC provider for Grafana, Miniflux, Jellyfin, Audiobookshelf. Self-signed TLS internally, Caddy terminates externally via `tls_insecure_skip_verify`. Provisioned declaratively via sops secrets. |

### Productivity / Home

| Service        | Port  | URL                        | Notes                         |
|----------------|-------|----------------------------|-------------------------------|
| Home Assistant | 8123  | `hass.<domain>`        | Podman OCI container; Alexa Smart Home; WoL for desktop; geoblock + rate-limit |
| Homepage       | 8082  | `home.<domain>`        | Dashboard (v2, from nixpkgs; `allowedHosts` set in the module) |
| Radicale       | 5232  | `cal.<domain>`         | CalDAV/CardDAV                |
| ntfy           | 9991  | `ntfy.<domain>`        | Push notifications            |
| Microbin       | 8069  | `microbin.<domain>`    | Paste bin                     |
| Atuin server   | 8881  | `atuin.<domain>`       | Shell history sync            |
| CouchDB        | 5984  | `livesync.<domain>`    | Obsidian LiveSync backend     |

### Kubernetes (k3s + ArgoCD)

**Status: enabled** — `./k3s` + `./argocd` imported in `modules/services/default.nix`, running on homeserver.

Single-node k3s on homeserver (`modules/services/k3s`). Embedded Traefik and
servicelb are **disabled** — homeserver's NixOS Caddy owns `:80/:443`; cluster
services are reached via NodePorts that kube-proxy serves on loopback only
(`--kube-proxy-arg=nodeport-addresses=127.0.0.0/8`, iptables proxier) — Caddy proxies
`localhost:<nodePort>`; NodePorts are not reachable from the LAN and the range is not opened in the firewall.

| Component | Notes |
|-----------|-------|
| k3s server | hand-rolled systemd unit, token from `secrets/k3s.yaml`. Kubeconfig `/etc/rancher/k3s/k3s.yaml` (mode 0640, group `wheel`) |
| ArgoCD | `v3.5.3`, pinned `install.yaml` via `pkgs.fetchurl`. Installed by `argocd-install` oneshot after `k3s.service`. UI on NodePort `30080` (`argocd-server-nodeport` svc) |
| Repo access | HTTPS to private `github.com/4rmcyt/gitops`, PAT = `git_access_token` from `secrets/common.yaml`, rendered into the `gitops-repo` Secret via `sops.templates` |
| Root app | Application `gitops` → `4rmcyt/gitops` path `k3s` (recurse), auto-sync prune + selfHeal |
| Workloads | `k3s/playground` (sandbox ns + quota/limitrange); `k3s/apps` app-of-apps → actions-runner-controller (`gha-runner-scale-set-controller` + account-level `gha-runner-scale-set` for `github.com/4rmcyt`, dind, 0–4 runners) |
| ARC auth | GitHub App; `modules/services/argocd/arc-github-app.nix` (not imported by default) provisions the `arc-github-app` Secret in `arc-runners` from `secrets/k3s.yaml` (`arc_github_app_*`) |

### AI / Local LLM

| Service   | Notes                                                                    |
|-----------|--------------------------------------------------------------------------|
| llama-cpp | Desktop only (`modules/TUI/ai-tools/llama-cpp`). All servers run the `ik_llama.cpp` fork (`inputs.ik-llama-cpp`, `.devops/nix/package.nix`); it lacks `--sleep-idle-seconds`, so idle unload is a socket-activated `systemd-socket-proxyd --exit-idle-time` in front of a `StopWhenUnneeded` backend. `default.nix`: Gemma 4 E4B on CUDA (sm_86 only), `:8080` socket → backend `:8092`, 15 min idle. `qwen32b-cpu.nix`: `Qwen2.5-32B-Instruct-Q4_K_M` (bartowski GGUF) for story.json generation, built with `-march=znver4`, `:8090` socket → backend `:8091`, 5 min idle. A lighter `cpu.nix` variant (Qwen2.5-3B, matebook, decommissioned) also exists. |

---

## Monitoring Stack (homeserver)

```
node_exporter (all hosts) ──┐
NUT exporter                ├──► Prometheus :9090 ──► Grafana :3003  ──► grafana.<domain>
Caddy metrics :2019         │         │
CrowdSec metrics :6060      │         └──► Alertmanager ──► alertmanager-ntfy ──► ntfy
                            │
systemd journal (every host, incl. Caddy access log)
  ──► systemd-journal-upload ──► VictoriaLogs :9428 ──► Grafana / CrowdSec (gcp-relay Caddy)
                                       └──► vmalert :8880 (LogsQL rules) ──► Alertmanager
```

- **Prometheus** scrape targets: homeserver, desktop, matebook, gcp-relay node exporters; NUT; Caddy; CrowdSec; Prometheus self
- **Grafana** OIDC via Kanidm; backend PostgreSQL; datasources: Prometheus + VictoriaLogs (`victoriametrics-logs-datasource`, uid `victorialogs`); `declarativePlugins` lists the core `prometheus` plugin too, since a declarative list replaces the preinstalled ones; dashboards from `modules/monitoring/grafana/dashboards/` (`victorialogs-logs.json` = System Logs)
- **Log shipping**: no agent. Every host runs systemd's own `systemd-journal-upload` (`modules/monitoring/journal-upload/`, `my.journalUpload`, zstd) to `/insert/journald`: desktop via `homeserver_lan:9429`, gcp-relay via `homeserver_ts:9429` (Caddy ingest front), homeserver directly via `127.0.0.1:9428`. VictoriaLogs derives stream fields `_MACHINE_ID, _HOSTNAME, _SYSTEMD_UNIT` and `level` (from `PRIORITY`: emerg, alert, critical, error, warning, notice, info, debug)
- **VictoriaLogs** (`modules/monitoring/victorialogs/`): retention 30d, data on `zdata/victorialogs` → `/var/lib/private/victorialogs` (DynamicUser). `-journald.useRemoteIP` stores the sender as `remote_ip`; no auth, so it listens on `127.0.0.1:9428` only — reads (Grafana, CrowdSec, vmalert) and homeserver's own journal-upload are local. Remote writers go through a write-only Caddy front `http://:9429` (`ports.victorialogs-ingest`): `POST /insert/journald/*` is proxied, anything else is 403, no access log (would loop back into VictoriaLogs). 9429 is reachable from the LAN only from desktop's addresses (`networking.firewall.extraInputRules`, nftables `ip saddr {desktop_lan, desktop_wifi}`) and on `tailscale0` only from gcp-relay (headscale ACL). VictoriaLogs takes `remote_ip` from `X-Forwarded-For` unconditionally, so it is only trustworthy behind Caddy, which drops clients' own XFF (they aren't in `trusted_proxies`) — CrowdSec's gcp-relay query pins that `remote_ip`
- **vmalert** (`vmalert-logs`, loopback only): LogsQL alert rules in `modules/monitoring/victorialogs/rules.nix` (type `vlogs`, explicit `_time` windows) → Alertmanager
- Not carried over from Alloy: the Python-container `level` downgrade (INFO/DEBUG on stderr marked error) — do it at query time if needed. Old Loki data stays on `zdata/loki` (`/var/lib/loki`, disko entry kept) until deleted manually
- **Alertmanager** → **alertmanager-ntfy** bridge → ntfy topic `alerts`
- **GeoIP** monthly auto-update from db-ip.com (city MMDB, no account required)
- Alert rules: `modules/monitoring/prometheus/alerts.yaml` (Prometheus), `modules/monitoring/victorialogs/rules.nix` (vmalert/LogsQL)

---

## Databases (homeserver)

| Service    | Notes                                          |
|------------|------------------------------------------------|
| PostgreSQL | Used by: Grafana, Miniflux, Atuin, others       |
| Redis      | Idle (no consumers since dispatcharr removal), loopback only |
| CouchDB    | Obsidian LiveSync backend (`livesync.<domain>`) |

---

## Secrets Layout

All encrypted with age. Key file: `/root/.config/sops/age/keys.txt` (all hosts), `~/.config/sops/age/keys.txt` (HM).

```
secrets/
  # Global / shared
  common.yaml                          # git_access_token, nix_access_token, gemini_api_key
  system.yaml                          # homeserver SSH host keys
  ssh.yaml                             # SSH keys

  # Per-host Tailscale auth
  tailscale-homeserver.yaml
  tailscale-desktop.yaml
  tailscale-matebook.yaml
  tailscale-gcp.yaml

  # Nix remote builds
  nix-builder-homeserver.yaml          # nix-builder SSH private key

  # Networking / TLS
  cloudflare_acme_credentials.env      # CF_DNS_API_TOKEN for Caddy ACME
  cloudflare.yaml                      # Cloudflare API token
  cloudflare_tunnel_cert.pem           # Cloudflare Tunnel account cert
  cloudflare_tunnel_credentials.bin    # Cloudflare Tunnel credentials
  wg.conf                              # WireGuard config
  gcp-relay-host-ed25519               # GCP SSH host key
  gcp-relay-age-key                    # GCP age encryption key (bootstrap only, not in the flake)

  # Security
  crowdsec.yaml                        # Caddy bouncer API key (homeserver)
  crowdsec-gcp.yaml                    # nftables bouncer API key (gcp-relay)

  # Databases
  postgresql.yaml                      # DB passwords (grafana, atuin, etc.)
  redis.yaml                           # Redis password
  couchdb.yaml                         # CouchDB admin credentials

  # Monitoring
  grafana.yaml                         # admin password, OIDC secret, secret key
  nut.yaml                             # NUT exporter password

  # Identity
  kanidm.yaml                          # Kanidm admin credentials, OIDC secrets

  # Services
  atuin.yaml                           # Atuin server credentials
  miniflux.env                         # Miniflux env secrets
  homepage.env                         # Homepage API keys
  job-kombayn.env                      # job-kombayn API keys (Anthropic, Telegram, Adzuna, RapidAPI)
  ntfy.yaml                            # ntfy auth config
  radicale.yaml                        # Radicale user credentials
  microbin.yaml                        # Microbin admin secret
  hass-alexa.yaml                      # Home Assistant Alexa skill credentials
  k3s.yaml                             # k3s server token; ARC GitHub App creds (arc_github_app_*)
  restic.yaml                          # Restic backup repository + password
  medialib.yaml                        # Media library credentials
  gmail_conf.yaml                      # Gmail / msmtp config
```
