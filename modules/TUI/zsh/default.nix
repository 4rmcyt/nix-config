{pkgs, ...}: {
  programs.zsh = {
    antidote = {
      enable = true;
      plugins = [
        "Aloxaf/fzf-tab"
        "MichaelAquilina/zsh-you-should-use"
        "getantidote/use-omz"
        "ohmyzsh/ohmyzsh path:plugins/command-not-found"
        "ohmyzsh/ohmyzsh path:plugins/direnv"
        "ohmyzsh/ohmyzsh path:plugins/docker"
        "ohmyzsh/ohmyzsh path:plugins/fzf"
        "ohmyzsh/ohmyzsh path:plugins/git"
        "ohmyzsh/ohmyzsh path:plugins/safe-paste"
        "ohmyzsh/ohmyzsh path:plugins/sudo"
        "romkatv/powerlevel10k"
        "zdharma-continuum/fast-syntax-highlighting"
        "zsh-users/zsh-autosuggestions"
        "zsh-users/zsh-completions"
        "zsh-users/zsh-history-substring-search"
      ];
      useFriendlyNames = true;
    };

    enable = true;

    initContent = ''
      autoload -Uz compinit && compinit

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

      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
      zstyle ':completion:*:*:docker:*' option-stacking yes
      zstyle ':completion:*:*:docker-*:*' option-stacking yes

      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
    '';

    # Initialize zoxide at the very end (required by zoxide doctor check)
    initExtraLast = ''
      eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"
    '';

    sessionVariables = {
      ALTERNATE_EDITOR = "${pkgs.vim}/bin/vi";
      LC_CTYPE = "en_US.UTF-8";
      LEDGER_COLOR = "true";
      LESS = "-FRSXM";
      LESSCHARSET = "utf-8";
      PAGER = "less";
    };

    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      ll = "ls -la";
      mc = "mc --nosubshell";
    };
  };
}
