lib: mcpServers: let
  mcpServerNames = builtins.attrNames mcpServers;
  mcpList = lib.concatMapStringsSep "\n" (name: "  - ${name}") mcpServerNames;
in ''
  ## Available MCP Servers
  ${mcpList}

  ## nix-config Project Layout

  Flake with 5 NixOS hosts: `desktop`, `gcp`, `homeserver`, `matebook`, `wsl`

  ```
  hosts/nixos/{host}/     # System config + hardware
  home/{host}/            # Home Manager per host
  modules/
    base/                 # Core system (logging, msmtp, distributed-builds)
    options/              # my.defaults.*, my.network.*, my.security.*
    WM/                   # Window managers (niri + noctalia-shell, gtk, mime, xdg)
    GUI/                  # GUI apps (firefox, chrome, obsidian, IDE, terminal, etc.)
    TUI/                  # Terminal tools (zsh, zellij, atuin, ai-tools)
    services/             # nixarr, homepage, miniflux, home-assistant, radicale, etc.
    networking/           # SSH, tailscale, traefik, headscale, cloudflared, nfs, etc.
    security/             # kanidm, crowdsec, fail2ban
    monitoring/           # prometheus, grafana, loki, alloy
    database/             # postgresql, redis, couchdb
    disko/                # Declarative disk partitioning per host
    fonts/                # System fonts
    gaming/               # Steam + gaming
    dev/                  # Developer tools
    nix/                  # Nix daemon variants (determinate, lix)
    users/                # Per-user NixOS config
    backup/               # Backup tooling
    containers/           # Container runtime config
    dots/                 # Dotfile management
    xdg/                  # XDG portal config
  secrets/                # sops-encrypted (NEVER commit plaintext)
  parts/                  # flake-parts modules (auto-imported via import-tree)
  ```

  ## Key Conventions

  **Options:** Use `my.defaults.*` (user, email, domain, IPs, timezone, locale) from `modules/options/defaults.nix`. Never hardcode these values.

  **Secrets:** sops-nix with age encryption. Reference via `config.sops.secrets.<name>.path`. Never expose values in code.

  **Formatting:** `nix fmt` runs treefmt (alejandra, deadnix, statix, prettier, shfmt, yamlfmt). Always format before committing.

  **Commits:** Conventional style: `type(scope): description` (feat, fix, refactor, style, chore). Scope = module or host name.

  **Nix Standards:**
  - Flakes-first. Pure, reproducible.
  - Home Manager for user-level, NixOS modules for system-level.
  - Single responsibility per module.
  - Verify changes: `nix build` or `nixos-rebuild build` before claiming success.

  **Anti-Patterns:**
  - Guessing file contents instead of reading via tools
  - Hardcoding values that exist in `my.defaults.*`
  - Plaintext secrets anywhere
  - Over-engineering or "future-proofing"

  ## CRITICAL: No Guessing on Unfamiliar Tools

  **NEVER make speculative config changes for tools you are not 100% certain about.**

  Before touching any plugin, library, or tool configuration:
  1. Search with `tavily` for documented behavior and known issues
  2. Check GitHub issues for known bugs
  3. Only propose a change backed by an actual source

  This applies to: zsh plugins, fzf integrations, desktop compositors, audio stacks, and any tool with complex interactions. Making wrong guesses that break the user's config is unacceptable. One web search takes seconds and prevents this.
''
