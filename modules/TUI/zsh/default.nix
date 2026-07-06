{
  config,
  lib,
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
        "romkatv/powerlevel10k"
        "zdharma-continuum/fast-syntax-highlighting"
        "zsh-users/zsh-autosuggestions"
        "zsh-users/zsh-history-substring-search"
        "rkh/zsh-jj"
        "elithrar/zsh-git-to-jj"
      ];
      useFriendlyNames = true;
    };

    enable = true;

    # Skip compaudit — completions are Nix-managed, always safe
    completionInit = "autoload -Uz compinit && compinit -C";

    # p10k instant prompt must be first — before any output
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        skip_global_compinit=1
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')
      ''
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

        # bracketed paste: use built-in only — bracketed-paste-magic triggers
        # syntax highlighting on every pasted character (O(n²) hang on large pastes)
        set zle_bracketed_paste

        # sudo: Esc-Esc to prepend sudo
        __sudo-replace-buffer() {
          local old=$1 new=$2 space=''${2:+ }
          if [[ $CURSOR -le ''${#old} ]]; then
            BUFFER="''${new}''${space}''${BUFFER#$old }"
            CURSOR=''${#new}
          else
            LBUFFER="''${new}''${space}''${LBUFFER#$old }"
          fi
        }
        sudo-command-line() {
          [[ -z $BUFFER ]] && LBUFFER="$(fc -ln -1)"
          local WHITESPACE=""
          if [[ ''${LBUFFER:0:1} = " " ]]; then WHITESPACE=" "; LBUFFER="''${LBUFFER:1}"; fi
          case "$BUFFER" in
            sudo\ *) __sudo-replace-buffer "sudo" "" ;;
            *) LBUFFER="sudo $LBUFFER" ;;
          esac
          LBUFFER="''${WHITESPACE}''${LBUFFER}"
          zle && zle redisplay
        }
        zle -N sudo-command-line
        bindkey '\e\e' sudo-command-line

        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' menu no
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
        zstyle ':completion:*:*:docker:*' option-stacking yes
        zstyle ':completion:*:*:docker-*:*' option-stacking yes

        # Disable gitstatus on headless hosts — it fails to initialize and hangs the prompt
        [[ $HOST == homeserver ]] && typeset -g POWERLEVEL9K_DISABLE_GITSTATUS=true
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
      ''
    ];

    sessionVariables = {
      ALTERNATE_EDITOR = "${pkgs.vim}/bin/vi";
      LC_CTYPE = "en_US.UTF-8";
      SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
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
      # git
      g = "git";
      ga = "git add";
      gaa = "git add --all";
      gapa = "git add --patch";
      gb = "git branch";
      gba = "git branch --all";
      gbd = "git branch --delete";
      gbD = "git branch --delete --force";
      gcb = "git checkout -b";
      gcl = "git clone --recurse-submodules";
      gcm = "git checkout main";
      gco = "git checkout";
      gd = "git diff";
      gds = "git diff --staged";
      gl = "git pull";
      glog = "git log --oneline --decorate --graph";
      gp = "git push";
      gpf = "git push --force-with-lease";
      grb = "git rebase";
      grba = "git rebase --abort";
      grbc = "git rebase --continue";
      grbi = "git rebase --interactive";
      grh = "git reset";
      grhh = "git reset --hard";
      gst = "git status";
      gsta = "git stash push";
      gstp = "git stash pop";
      gsw = "git switch";
      gswc = "git switch --create";
    };
  };
}
