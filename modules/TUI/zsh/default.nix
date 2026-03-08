{
  config,
  pkgs,
  ...
}: {
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    # Use XDG config directory for zsh (new default behavior)
    dotDir = "${config.xdg.configHome}/zsh";

    antidote = {
      enable = true;
      plugins = [
        "Aloxaf/fzf-tab"
        "MichaelAquilina/zsh-you-should-use"
        "getantidote/use-omz"
        "ohmyzsh/ohmyzsh path:plugins/direnv"
        "ohmyzsh/ohmyzsh path:plugins/docker"
        "ohmyzsh/ohmyzsh path:plugins/git"
        "ohmyzsh/ohmyzsh path:plugins/safe-paste"
        "ohmyzsh/ohmyzsh path:plugins/sudo"
        "romkatv/powerlevel10k"
        "zdharma-continuum/fast-syntax-highlighting"
        "zsh-users/zsh-autosuggestions"
        "zsh-users/zsh-history-substring-search"
      ];
      useFriendlyNames = true;
    };

    enable = true;

    # Skip compaudit — completions are Nix-managed, always safe
    completionInit = "autoload -U compinit && compinit -C";

    # Must run before anything else — p10k instant prompt requires this at the very top
    initExtraFirst = ''
      skip_global_compinit=1
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
    '';

    initContent = ''
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

      # Disable gitstatus on headless hosts — it fails to initialize and hangs the prompt
      [[ $HOST == homeserver ]] && typeset -g POWERLEVEL9K_DISABLE_GITSTATUS=true
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
    '';

    sessionVariables = {
      ALTERNATE_EDITOR = "${pkgs.vim}/bin/vi";
      LC_CTYPE = "en_US.UTF-8";
      LEDGER_COLOR = "true";
      LESS = "-FRSXM";
      LESSCHARSET = "utf-8";
      SYSTEMD_LESS = "FRSXMK";
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
