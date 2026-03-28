# Home Manager config for Galaxy S23+ (nix-on-droid)
# Tailscale: install Android app for daemon — CLI here for status/ssh/ping
{
  config,
  pkgs,
  ...
}: {
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  xdg.enable = true;

  # ── Secrets ───────────────────────────────────────────────────────────────────
  # sops-nix requires systemd which is not available on nix-on-droid.
  # SSH key: copy manually after deploy:
  #   mkdir -p ~/.ssh && age -d -i ~/.config/sops/age/keys.txt secrets/ssh.yaml > ~/.ssh/id_ed25519
  # Atuin: run `atuin login` manually after deploy.

  # ── Git ──────────────────────────────────────────────────────────────────────
  # No GPG signing — no hardware key on Android
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "4rmcyt";
        email = "redacted@example.com";
      };
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
      core.editor = "hx";
    };
    signing.format = null;
  };

  # ── Shell: Zsh ───────────────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    # Skip compaudit — completions Nix-managed
    completionInit = "autoload -Uz compinit && compinit -C";
    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      share = true;
      path = "${config.xdg.dataHome}/zsh/history";
    };
    initContent = ''
      bindkey '^f' autosuggest-accept
      bindkey '^p' history-search-backward
      bindkey '^n' history-search-forward
      bindkey '^[[A' history-search-backward
      bindkey '^[[B' history-search-forward

      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' menu select

      # Tailscale helpers — daemon is the Android Tailscale app
      ts-status() { tailscale status; }
      ts-ssh()    { tailscale ssh "$@"; }
      ts-nc()     { tailscale nc "$@"; }

      # Quick SSH to homelab
      hs()        { ssh zeev@homeserver "$@"; }
      dt()        { ssh zeev@desktop "$@"; }
    '';
    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      ls = "${pkgs.eza}/bin/eza --icons";
      ll = "${pkgs.eza}/bin/eza -la --icons --git";
      lt = "${pkgs.eza}/bin/eza --tree --icons";
      cat = "${pkgs.bat}/bin/bat";
      grep = "${pkgs.ripgrep}/bin/rg";
      find = "${pkgs.fd}/bin/fd";
      # git shortcuts
      g = "git";
      gst = "git status";
      gd = "git diff";
      gp = "git push";
      gl = "git pull";
      glog = "git log --oneline --decorate --graph";
      ga = "git add";
      gaa = "git add --all";
      gcm = "git commit -m";
      # zellij
      zj = "zellij";
      # nix shortcuts
      ne = "nix-on-droid switch --flake ~/src/nix-config#s23plus --option pure-eval false --option fallback true; ls /nix/store/*home-manager-generation*/activate 2>/dev/null | sort | tail -1 | sh";
    };
  };

  # ── Prompt: Starship ─────────────────────────────────────────────────────────
  # Lighter than p10k+antidote, no extra deps, has Android OS symbol
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      format = "$os$username$directory$git_branch$git_status$nix_shell$python$rust$golang$character";
      line_break.disabled = true;
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
      os = {
        disabled = false;
        symbols.Android = " ";
      };
      username = {
        show_always = false; # show only in SSH
        style_user = "bold cyan";
        format = "[$user]($style)@";
      };
      directory = {
        style = "bold blue";
        truncation_length = 4;
        truncation_symbol = "…/";
      };
      git_branch = {
        symbol = " ";
        style = "bold yellow";
        format = "[$symbol$branch]($style) ";
      };
      git_status = {
        style = "bold red";
        format = "([\\[$all_status$ahead_behind\\]]($style) )";
      };
      nix_shell = {
        symbol = "󱄅 ";
        style = "bold purple";
        format = "[$symbol$name]($style) ";
        heuristic = true;
      };
    };
  };

  # ── Shell history: Atuin ─────────────────────────────────────────────────────
  # Syncs history across all devices. After deploy: run `atuin login`
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = ["--disable-up-arrow"];
    settings = {
      auto_sync = true;
      sync_frequency = "30m";
      sync_address = "https://atuin.example.com";
      update_check = false;
      filter_mode = "global";
      filter_mode_shell_up_key_binding = "session";
      enter_accept = true;
      style = "compact";
      inline_height = 10;
      search_mode = "fuzzy";
      prefers_reduced_motion = true;
      key_path = "${config.home.homeDirectory}/.local/share/atuin/key";
session_path = "${config.home.homeDirectory}/.local/share/atuin/session";
      # After deploy:
      # Atuin: run `atuin login` OR copy.   key+session from another machine:
#   scp homeserver:~/.local/share/atuin/key ~/.local/share/atuin/key
#   scp homeserver:~/.local/share/atuin/session ~/.local/share/atuin/session
    };
  };

  # ── Multiplexer: Zellij ──────────────────────────────────────────────────────
  programs.zellij = {
    enable = true;
    settings = {
      on_force_close = "detach";
      default_mode = "locked";
      mouse_mode = true;
      scroll_buffer_size = 10000;
      copy_on_select = false; # no wl-clipboard on Android
      show_startup_tips = false;
      show_release_notes = false;
      session_serialization = true;
      serialization_interval = 60;
      pane_frames = true;
      theme = "catppuccin-frappe";
      ui.pane_frame = {
        rounded_corners = true;
        hide_session_name = false;
      };
    };
  };

  # Mobile-friendly zellij layout: single pane + compact bar
  home.file.".config/zellij/layouts/mobile.kdl".text = ''
    layout {
      pane
      pane size=1 borderless=true {
        plugin location="zellij:compact-bar"
      }
    }
  '';

  # ── Editor: Helix ────────────────────────────────────────────────────────────
  # No LSP on Android — just syntax highlighting and editing
  programs.helix = {
    enable = true;
    settings = {
      editor = {
        line-number = "relative";
        cursorline = true;
        true-color = true;
        cursor-shape.insert = "bar";
        cursor-shape.select = "underline";
        mouse = false; # touch scrolling interferes
        bufferline = "multiple";
        lsp.display-messages = false;
        file-picker.hidden = false;
      };
      theme = "catppuccin_frappe";
    };
  };

  # ── File manager: Yazi ───────────────────────────────────────────────────────
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    enableZshIntegration = true;
    settings = {
      manager = {
        ratio = [1 3 4]; # more space for preview on narrow screens
        show_hidden = true;
        show_symlink = true;
      };
      preview.max_width = 600;
    };
  };

  # ── Fuzzy finder: Fzf ────────────────────────────────────────────────────────
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "${pkgs.fd}/bin/fd --type f";
    defaultOptions = ["--border" "--layout=reverse" "--height=50%"];
    colors = {
      "bg+" = "#414559";
      fg = "#c6d0f5";
      "fg+" = "#c6d0f5";
      hl = "#a6d189";
      "hl+" = "#a6d189";
      pointer = "#f4b8e4";
      prompt = "#8caaee";
    };
  };

  # ── Smart cd: Zoxide ─────────────────────────────────────────────────────────
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = ["--cmd cd"];
  };

  # ── Dev env isolation: Direnv ────────────────────────────────────────────────
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # ── Shell completions: Carapace ──────────────────────────────────────────────
  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
  };

  # ── Git TUI: Lazygit ─────────────────────────────────────────────────────────
  programs.lazygit.enable = true;

  # ── GitHub CLI ───────────────────────────────────────────────────────────────
  programs.gh.enable = true;

  # ── Offline man pages: Tealdeer ──────────────────────────────────────────────
  programs.tealdeer = {
    enable = true;
    settings.updates = {
      auto_update = true;
      auto_update_interval_hours = 168; # weekly — save mobile data
    };
  };

  # ── Bat ──────────────────────────────────────────────────────────────────────
  programs.bat = {
    enable = true;
    config = {
      theme = "catppuccin-frappe";
      style = "numbers,changes";
      pager = "less -FR";
    };
  };

  # ── SSH ───────────────────────────────────────────────────────────────────────
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      homeserver = {
        hostname = "homeserver";
        user = "zeev";
        compression = true;
        identityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };
      desktop = {
        hostname = "desktop";
        user = "zeev";
        compression = true;
        identityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };
    };
  };

  # Packages are managed at nix-on-droid level (environment.packages)
  # Only add packages here that are HM-specific
  home.packages = with pkgs; [
    file
  ];

  home.sessionVariables.TERM = "xterm-256color";
}
