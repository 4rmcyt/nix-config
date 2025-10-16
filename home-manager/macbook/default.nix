{pkgs, ...}: {
  home = {
    stateVersion = "25.05";
    username = "zeev";
    homeDirectory = "/home/zeev";
    packages = with pkgs; [
      # Shell & Editor
      zsh
      neovim
      vim
      cachix
      # Dev tools
      direnv
      git
      gh
      just
      nixfmt-rfc-style
      nil
      shfmt
      helix
      rustfmt
      # User Utils
      jq
      nix-index
      fzf
      zip
      unzip
      tree
      zoxide
      statix
      deadnix

      # Security & Crypto
      gnupg
      pinentry-tty

      # GUI applications - these will get Start Menu shortcuts
      ghostty
      obsidian
      firefox
      vscode

      # WSL-specific tools
      wslu # WSL utilities

      # Additional packages from macbook config
      btop
      htop
      delta
      pwgen
      tmux
      zsh-powerlevel10k
    ];
  };

  programs = {
    git = {
      enable = true;
      userName = "zeev";
      userEmail = "zeev@example.com"; # Update with your email
      extraConfig = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
      };
    };

    gpg = {
      enable = true;
      homedir = "/home/zeev/.gnupg";
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
        ll = "ls -la";
        la = "ls -la";
        ".." = "cd ..";
        "..." = "cd ../..";
        rebuild = "sudo nixos-rebuild switch --flake .#wsl";
      };

      sessionVariables = {
        EDITOR = "nvim";
        ALTERNATE_EDITOR = "${pkgs.vim}/bin/vi";
        LC_CTYPE = "en_US.UTF-8";
        LESS = "-FRSXM";
        LESSCHARSET = "utf-8";
        PAGER = "less";
      };

      profileExtra = ''
        export GPG_TTY=$(tty)
        if ! pgrep -x "gpg-agent" > /dev/null; then
            ${pkgs.gnupg}/bin/gpgconf --launch gpg-agent
        fi

        export PATH=/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
            . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi

        [ -d "$HOME/bin" ] && PATH="$HOME/bin:$PATH"
        [ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"
      '';

      initContent = ''
        autoload -Uz compinit && compinit

        bindkey -v
        bindkey '^f' autosuggest-accept
        bindkey '^p' history-search-backward
        bindkey '^n' history-search-forward
        bindkey '^[w' kill-region

        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
        HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

        # Fix Home/End/Delete keys
        bindkey '\e[H' beginning-of-line
        bindkey '\e[F' end-of-line
        bindkey '\e[1~' beginning-of-line
        bindkey '\e[4~' end-of-line
        bindkey '\e[3~' delete-char

        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' menu no
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
      '';

      antidote = {
        enable = true;
        useFriendlyNames = true;
        plugins = [
          "getantidote/use-omz"

          # Oh My Zsh plugins
          "ohmyzsh/ohmyzsh path:plugins/command-not-found"
          "ohmyzsh/ohmyzsh path:plugins/direnv"
          "ohmyzsh/ohmyzsh path:plugins/docker"
          "ohmyzsh/ohmyzsh path:plugins/git"
          "ohmyzsh/ohmyzsh path:plugins/fzf"
          "ohmyzsh/ohmyzsh path:plugins/rust"
          "ohmyzsh/ohmyzsh path:plugins/safe-paste"
          "ohmyzsh/ohmyzsh path:plugins/z"
          "ohmyzsh/ohmyzsh path:plugins/zoxide"
          "ohmyzsh/ohmyzsh path:plugins/sudo"

          # Community plugins
          "zsh-users/zsh-completions"
          "zsh-users/zsh-autosuggestions"
          "zsh-users/zsh-history-substring-search"
          "zdharma-continuum/fast-syntax-highlighting"
          "MichaelAquilina/zsh-you-should-use"
          "Aloxaf/fzf-tab"
          "romkatv/powerlevel10k"
        ];
      };
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--info=inline"
        "--border"
        "--exact"
      ];
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = ["--cmd cd"];
    };

    gh = {
      enable = true;
      settings = {
        editor = "nvim";
        git_protocol = "ssh";
      };
    };

    nix-index.enable = true;
  };

  # Enable XDG for desktop files
  xdg = {
    enable = true;
    mimeApps.enable = true;
  };
}
