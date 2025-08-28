{
  pkgs,
  lib,
  ...
}:
{
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
      nerd-fonts.hack
    ];
  };
  
  programs = {
    git = {
    enable = true;
    userName = "4rmcyt";
    userEmail = "4rmcyt@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
      # Fix line ending issues
      core.autocrlf = "input";
      core.eol = "lf";
      };
    };

    gpg = {
      enable = true;
      homedir = "/home/zeev/.gnupg";
    };

    zsh = {
      enable = true;
      shellAliases = {
        ll = "ls -la";
        ".." = "cd ..";
        "..." = "cd ../..";
      };

      sessionVariables = {
        EDITOR = "helix";
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

        bindkey '^[[A' history-substring-search-up # or '\eOA'
        bindkey '^[[B' history-substring-search-down # or '\eOB'
        HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

        # Fix Home/End/Delete keys in iTerm2
        bindkey '\e[H' beginning-of-line
        bindkey '\e[F' end-of-line
        bindkey '\e[1~' beginning-of-line
        bindkey '\e[4~' end-of-line
        bindkey '\e[3~' delete-char

        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' menu no
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
        zstyle ':completion:*:*:docker:*' option-stacking yes
        zstyle ':completion:*:*:docker-*:*' option-stacking yes

        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        if [ $(command -v fortune) ] && [ $UID != '0' ] && [[ $- == *i* ]] && [ $TERM != 'dumb' ]; then
            ### Cowsay At Login ###
            if [ $(command -v cowsay) ]; then
                fortune -a fortunes wisdom | cowsay
            else
                fortune -a fortunes wisdom
            fi
        fi
      '';
      antidote = {
        enable = true;
        useFriendlyNames = true;
        plugins = [
          "getantidote/use-omz"

          # Oh My Zsh plugins (no duplicates)
          "ohmyzsh/ohmyzsh path:plugins/ansible"
          "ohmyzsh/ohmyzsh path:plugins/aws"
          "ohmyzsh/ohmyzsh path:plugins/bazel"
          "ohmyzsh/ohmyzsh path:plugins/brew"
          "ohmyzsh/ohmyzsh path:plugins/command-not-found"
          "ohmyzsh/ohmyzsh path:plugins/direnv"
          "ohmyzsh/ohmyzsh path:plugins/docker"
          "ohmyzsh/ohmyzsh path:plugins/git"
          "ohmyzsh/ohmyzsh path:plugins/fzf"
          "ohmyzsh/ohmyzsh path:plugins/poetry"
          "ohmyzsh/ohmyzsh path:plugins/pyenv"
          "ohmyzsh/ohmyzsh path:plugins/python"
          "ohmyzsh/ohmyzsh path:plugins/rust"
          "ohmyzsh/ohmyzsh path:plugins/safe-paste"
          "ohmyzsh/ohmyzsh path:plugins/z"
          "ohmyzsh/ohmyzsh path:plugins/zoxide"
          "ohmyzsh/ohmyzsh path:plugins/sudo"

          # Separate community plugins
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
      options = [ "--cmd cd" ];
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
  
  home-manager.backupFileExtension = "backup";

}