# nix-config

> 4rmcyt's NixOS fleet — five machines, one flake, zero hand-editing.

A [flake-parts](https://flake.parts) + [`import-tree`](https://github.com/vic/import-tree)
configuration that builds and deploys every machine I run: a workstation, a
laptop, a home server, a VLAN router, and a public cloud relay. Each host is a
composition of small single-responsibility modules; identity and LAN topology
live in a separate private flake so this repo can stay public.

---

## Hosts

| Host | Hardware | Role | Desktop / notable stack |
|------|----------|------|--------------------------|
| **desktop** | AMD Zen 4, NVIDIA | Workstation | Wayland via **mango** (`wl-only`, Vulkan renderer for HDR) + **noctalia** shell; gaming, libvirt/virt-manager, waydroid, CUDA caches |
| **matebook** | AMD Zen 1 laptop | Mobile workstation | **niri** + noctalia; Limine + Secure Boot, suspend-then-hibernate, auto-cpufreq |
| **homeserver** | Intel Skylake | Services host | Traefik, media stack (nixarr), Postgres/Redis/CouchDB, monitoring, Kanidm, CrowdSec, restic backups |
| **gcp-relay** | GCP `e2-micro` | Tailnet relay | **Headscale** control plane + DERP server, Caddy TLS, fail2ban, hardened |
| **router** | Sophos SG appliance (Intel Atom) | Edge router | nftables firewall, Kea DHCP, Unbound resolver, VLAN segmentation, mDNS reflector — headless, no HM |

Build any host:

```bash
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
```

Deploy targets are wired in the [`justfile`](justfile) (`just deploy-homeserver`,
`just deploy-matebook`, `just deploy-gcp`, …).

---

## Repository layout

```
flake.nix                 # ~15 lines — delegates everything to import-tree ./parts
parts/                    # flake-parts modules, auto-imported
  owner.nix               # maps private identity/topology onto meta.owner.*
  meta.nix / flake-parts-modules.nix   # internal options (not flake outputs)
  configurations/nixos.nix             # configurations.nixos.<name> → flake.nixosConfigurations
  shared-nixos-settings.nix            # nix daemon, binary caches, sops, access tokens
  hm.nix / home-manager-*.nix          # Home Manager wiring (skipped on router + gcp-relay)
  workstation.nix          # facter + ucodenix + gnupg — desktop/laptop/server only
  hosts/<host>/configuration.nix       # per-host composition
  formatting.nix / devshells.nix / topology.nix / schemas.nix
hosts/nixos/<host>/       # hardware-configuration.nix, facter.json, host NixOS config
home/<host>/              # Home Manager config per host
modules/                  # ~190 single-responsibility modules
  base/ options/ roles/   # core system, my.defaults.*, role compositions
  WM/ GUI/ TUI/           # mango, niri, noctalia, firefox/chrome, zsh, zellij, ai-tools, …
  services/               # nixarr, homepage, miniflux, home-assistant, atuin-server,
                          #   komga/komf, dispatcharr, microbin, ntfy, radicale
  networking/             # traefik, caddy, headscale, tailscale, unbound, dnssec, nfs, wireguard, nut
  security/ monitoring/ database/      # kanidm, crowdsec, fail2ban / prometheus+grafana+loki+alloy / postgres+redis+couchdb
  disko/ backup/ containers/ nix/      # declarative disks, restic, podman, lix/determinate
secrets/                  # sops-encrypted YAML/env (age)
infra/tf/gcp-relay/       # OpenTofu — GCP instance + static IP for the relay
docs/                     # Architecture / Infrastructure / CI-CD / hardware notes
```

### How a host is assembled

`parts/hosts/<host>/configuration.nix` defines `configurations.nixos.<name>.module`,
which `parts/configurations/nixos.nix` turns into `flake.nixosConfigurations.<name>`
via `lib.nixosSystem`. Each host imports three shared deferred modules —
`modules.nixos.base` (nix settings, caches, sops), `modules.nixos.hm` (Home
Manager), `modules.nixos.workstation` (microcode, facter, gnupg) — plus its
`hosts/nixos/<host>` tree and whatever input modules it needs. `deferredModule`
merge semantics let several `parts/` files contribute to the same base.

---

## Conventions

- **Metadata:** `config.meta.owner.*` in flake-parts scope, `config.my.defaults.*`
  in NixOS modules — both resolve from the private `private` flake input
  (`git+ssh://…/nix-config-private`). Never hardcoded. See
  [`modules/options/private-example.nix`](modules/options/private-example.nix)
  for the schema.
- **Secrets:** [sops-nix](https://github.com/Mic92/sops-nix) + age. Referenced as
  `config.sops.secrets.<name>.path`; plaintext never enters the repo. Age keys at
  `/root/.config/sops/age/keys.txt` (system) and `~/.config/sops/age/keys.txt` (HM).
- **Formatting:** `nix fmt` runs [treefmt](treefmt.nix) — alejandra, deadnix,
  statix, prettier, shfmt/shellcheck, yamlfmt, toml-sort, rustfmt, opentofu.
- **Commits:** Conventional — `type(scope): description`, scope = module or host.
- **NixOS vs Home Manager:** system-level config in `modules/`, user-level in `home/`.
- **Never guess config keys** — read the upstream schema before writing any
  daemon/service option.

---

## Networking & remote access

All machines join a self-hosted [Headscale](https://headscale.net) tailnet whose
control plane and a DERP region run on **gcp-relay** (`hs.<domain>`, reached over
Caddy TLS). The homeserver advertises its LAN subnet and an exit node; the router
advertises the media VLAN. Split DNS for the private domain is served by Unbound
(on the router and homeserver) with a NextDNS DoT upstream. Public service
ingress on the homeserver terminates at **Traefik** with a Cloudflare DNS-01
wildcard cert and a CrowdSec bouncer.

Roughly what's published behind Traefik (`*.<domain>`):

`home` (homepage) · `grafana` · `miniflux` · `hass` · `jellyfin` · `sonarr` /
`radarr` / `prowlarr` / `bazarr` / `lidarr` / `seerr` / `qb` · `audiobookshelf` ·
`lazylibrarian` · `kapowarr` · `komga` / `komf` · `dispatcharr` · `atuin` ·
`ntfy` · `cal` (radicale) · `microbin` · `livesync` (CouchDB) · `idm` (Kanidm) ·
`jobko` · `traefik`

---

## CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) is an orchestrator over
reusable workflows:

```
flake-lock-update (schedule/dispatch only)
  ├─ validate            nix fmt + flake check          (non-blocking, warns via Telegram)
  └─ security-checks     Trivy · TruffleHog · SOPS · syntax   (hard gate)
        └─ build-and-check-systems   real toplevel build of homeserver, matebook, gcp-relay
              └─ workflow-summary    Telegram notification
vulnix-scan   (schedule/dispatch only) — CVE scan of a built closure
```

`desktop` is intentionally excluded from CI builds — its full GUI/CUDA closure
exceeds GitHub-hosted runner limits; it's built on the machine itself. Per-host
builds are pushed to per-host Cachix caches (`4rmcyt-<host>.cachix.org`).

---

## Local development

```bash
nix develop          # tooling shell: sops, age, gitleaks, ripsecrets, nh, nix-tree, …
nix fmt              # format everything
nix flake check      # validate outputs
just topology        # render nix-topology diagrams into docs/ (git-ignored)
```

`just topology` builds `docs/topology.svg` (physical) and `docs/topology-network.svg`
(network-centric) from the NixOS configs via
[nix-topology](https://github.com/oddlama/nix-topology) — annotations in
[`modules/topology/`](modules/topology/default.nix) and
[`parts/topology.nix`](parts/topology.nix). The SVGs are git-ignored: they resolve
real host addresses from the private flake input, so they stay local.

---

## Key inputs

`nixpkgs` (unstable) · `flake-parts` · `import-tree` · `home-manager` ·
`sops-nix` · `disko` · `impermanence` · `nixos-facter-modules` · `nixos-anywhere` ·
`determinate` / lix · `mango` · `niri-flake` · `noctalia` · `stylix` · `nixvim` ·
`nix-vscode-extensions` · `nixarr` · `arr-packages` (own) · `headscale` ·
`nix-topology` · `nix-flatpak` · `mcp-nixos` / `mcp-servers-nix` · `nix-index-database` ·
`auto-cpufreq` · `ucodenix` · `private` (own, identity/topology).

---

## Docs

| File | Covers |
|------|--------|
| [docs/Architecture.md](docs/Architecture.md) | Flake structure, `parts/`, module layout, options system |
| [docs/Infrastructure.md](docs/Infrastructure.md) | Homeserver services, ZFS layout, ports, networking |
| [docs/CI-CD.md](docs/CI-CD.md) | Full pipeline diagram and per-workflow detail |
| [docs/gcp.md](docs/gcp.md) | gcp-relay deploy + first-boot |
| [docs/router-installation.md](docs/router-installation.md), [docs/efi.md](docs/efi.md), [docs/bios-desktop-settings.md](docs/bios-desktop-settings.md) | Hardware / firmware notes |
