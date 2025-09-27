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
      helix

      # Dev tools
      direnv
      git
      gh
      go
      deploy-rs
      just
      nixfmt-rfc-style
      nixfmt-tree
      nil
      nix-fast-build
      nix-inspect
      nix-diff
      shfmt
      rustfmt
      cachix

      # User Utils
      jq
      nix-index
      fzf
      zip
      unzip
      unar
      p7zip
      tree
      zoxide
      statix
      deadnix
      pass
      dive
      yamllint
      trash-cli
      borgbackup
      nextdns
      nh
      nix-output-monitor
      nvd
      pyenv
      sudo

      # Security & Crypto
      gnupg
      pinentry-tty

      # GUI applications - these will get Start Menu shortcuts
      ghostty
      ghostty.terminfo
      obsidian
      firefox
      vscode

      # WSL-specific tools
      wslu

      # System & Monitoring Tools
      btop
      htop
      delta
      pwgen
      tmux
      tuptime
      home-manager
      mc

      # Add these for fun terminal stuff
      fortune
      cowsay

      # Fonts & Themes
      zsh-powerlevel10k
      nerd-fonts.hack
      meslo-lgs-nf
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
        core.autocrlf = "input";
        core.eol = "lf";
        core.safecrlf = true;
      };
    };

    gpg = {
      enable = true;
      homedir = "/home/zeev/.gnupg";
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      colors = {
        fg = "#D8DEE9";
        bg = "#2E3440";
        hl = "#A3BE8C";
        "fg+" = "#D8DEE9";
        "bg+" = "#434C5E";
        "hl+" = "#A3BE8C";
        pointer = "#BF616A";
        info = "#4C566A";
        spinner = "#4C566A";
        header = "#4C566A";
        prompt = "#81A1C1";
        marker = "#EBCB8B";
      };
    };

    zsh = {
      enable = true;
      shellAliases = {
        ll = "ls -la";
        mc = "mc --nosubshell";
        ".." = "cd ..";
        "..." = "cd ../..";
        rebuild = "sudo nixos-rebuild switch --flake .#wsl";
      };

      sessionVariables = {
        EDITOR = "nvim";
        ALTERNATE_EDITOR = "${pkgs.vim}/bin/vi";
        LC_CTYPE = "en_US.UTF-8";
        LEDGER_COLOR = "true";
        LESS = "-FRSXM";
        LESSCHARSET = "utf-8";
        PAGER = "less";
      };

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

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };

    helix = {
      enable = true;
      settings = {
        theme = "heisenberg";
        editor = {
          true-color = true;
          line-number = "relative";
          mouse = false;
          cursorline = true;
          bufferline = "multiple";
          default-line-ending = "lf";
          cursor-shape.insert = "bar";
          cursor-shape.select = "underline";
          lsp.display-inlay-hints = true;
          lsp.display-messages = true;
          file-picker.hidden = false;
          file-picker.git-ignore = true;
        };
      };
      languages.language = [
        {
          name = "nix";
          auto-format = true;
          formatter.command = lib.getExe pkgs.nixfmt-rfc-style;
        }
      ];
    };

    ghostty = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        theme = "Dracula+";
        background-blur-radius = 40;
        background-opacity = 0.8;
        background-blur = true;
        minimum-contrast = 1.1;
        font-size = 14;
        font-family = "MesloLGS NF";
        window-theme = "system";
        window-show-tab-bar = "always";
        gtk-titlebar = true;
        shell-integration-features = "sudo";
      };
    };
  };

  services = {
    ssh-agent.enable = true;
  };

  # Enable XDG for desktop files
  xdg = {
    enable = true;
    mimeApps.enable = true;
  };
}
