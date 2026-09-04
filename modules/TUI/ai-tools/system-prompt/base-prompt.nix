lib: mcpServers: let
  mcpServerNames = builtins.attrNames mcpServers;
  mcpList = lib.concatMapStringsSep "\n" (name: "  - ${name}") mcpServerNames;
in ''
  ## Available MCP Servers
  ${mcpList}

  ## nix-config Project Layout

  Flake with 5 NixOS hosts: `desktop`, `gcp-relay`, `homeserver`, `matebook`, `router` (router not currently deployed)

  ```
  hosts/nixos/{host}/     # System config + hardware
  home/{host}/            # Home Manager per host
  modules/
    base/                 # Core system (logging, msmtp)
    options/              # my.defaults.*, my.network.*, my.security.*
    WM/                   # niri + mango (both w/ noctalia v5), gtk, mime — desktop:mango, matebook:niri; hyprland kept on disk unused, not migrated off noctalia legacy-v4
    GUI/                  # firefox, chrome, obsidian, zed, terminal, mpv, etc.
    TUI/                  # zsh, zellij, atuin, starship, neovim, ai-tools (claude-code, llama-cpp, mcp)
    services/             # homepage, miniflux, home-assistant, atuin-server, nixarr,
                          # dispatcharr, komga, komf, microbin, ntfy, radicale, argocd (disabled), k3s (disabled)
    networking/           # ssh, tailscale, traefik, caddy, headscale,
                          # cloudflared, wireguard, nfs, nfs-client, unbound, avahi, dnssec, nut-server, nut-client
    security/             # kanidm, crowdsec, fail2ban, hardening
    monitoring/           # prometheus, grafana, loki, alloy, alerts, node-exporter
    database/             # postgresql, redis, couchdb
    disko/                # Declarative disk partitioning per host
    users/                # Per-user NixOS config (zeev)
    backup/               # Backup tooling (restic)
    containers/           # Podman container support
    dev/                  # Developer tools
    dots/                 # Dotfile management
    nix/                  # Nix daemon variants (lix)
  parts/                  # flake-parts modules (auto-imported via import-tree)
  secrets/                # sops-encrypted YAML (NEVER commit plaintext)
  ```

  ## Key Conventions

  **Metadata:** Use `config.meta.owner.*` in flake-parts scope, and `config.my.defaults.*` in NixOS module scope. Never hardcode them.

  **Secrets:** sops-nix + age. Reference as `config.sops.secrets.<name>.path`. Never expose values in code.

  **Formatting:** `nix fmt` via treefmt (alejandra for Nix). Always format before committing.

  **Commits:** Conventional style: `type(scope): description`. Scope = module name or host.

  **NixOS vs HM boundary:** System-level config in NixOS modules. User-level config in Home Manager.

  **Anti-Patterns:**
  - Guessing file contents instead of reading via tools
  - Hardcoding values that exist in `my.defaults.*`
  - Plaintext secrets anywhere
  - Over-engineering or "future-proofing"
  - Running `nix build` or `nixos-rebuild` — the user builds himself

  ## CRITICAL: Never guess config keys

  Before writing ANY config key for ANY app or daemon — fetch the official docs first (`fetch` or `tavily`). Never guess option names. Read the schema, then write. No exceptions.

  ## CRITICAL: Never use sudo over SSH to remote hosts

  Never run `sudo` (directly or via `sudo -n`/`sudo -u`) when SSH'd into a remote host (homeserver, gcp, etc.). No exceptions, no "just to read something" — includes read-only queries (e.g. `sudo -u <service-user> psql ...`). Use the app's own read path (its API, its own service account if it's the SSH user, etc.) instead. If that's not enough, ask the user to run the command himself.
''
