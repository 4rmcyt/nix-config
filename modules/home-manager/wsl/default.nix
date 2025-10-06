{
  pkgs,
  lib,
  ...
}: {
  home = {
    username = "zeev";
    homeDirectory = "/home/zeev";
    stateVersion = "25.05";
    packages = with pkgs; [
      # Development tools
      cachix
      deadnix
      delta
      deploy-rs
      direnv
      gh
      git
      go
      just
      nil
      nix-diff
      nix-fast-build
      nix-inspect
      nixfmt-rfc-style
      nixfmt-tree
      pyenv
      rustfmt
      shfmt
      statix

      # Editors
      helix
      neovim
      vim

      # Fonts & Themes
      meslo-lgs-nf
      nerd-fonts.hack
      zsh-powerlevel10k

      # Fun terminal utilities
      cowsay
      fortune

      # GUI applications (with Start Menu shortcuts)
      firefox
      ghostty
      ghostty.terminfo
      obsidian
      vscode-fhs

      # Nix utilities
      nh
      nix-index
      nix-output-monitor
      nvd

      # Security & Crypto
      gnupg
      pass
      pinentry-tty

      # Shell
      zsh

      # System & Monitoring tools
      btop
      home-manager
      htop
      mc
      nextdns
      pwgen
      sudo
      tmux
      tuptime

      # User utilities
      borgbackup
      dive
      fzf
      jq
      p7zip
      trash-cli
      tree
      unar
      unzip
      yamllint
      zip
      zoxide

      # WSL-specific tools
      wslu
    ];
  };

  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
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

    git = {
      enable = true;
      userName = "4rmcyt";
      userEmail = "4rmcyt@gmail.com";
      signing.key = "FD1AA16D16ACD8A003AD6D7AD85B52C9288A138E";
      extraConfig = {
        commit.gpgsign = true;
        gpg.format = "ssh";
        user.signingkey = "~/.ssh/zeev";
      };
    };

    gpg = {
      enable = true;
      homedir = "/home/zeev/.gnupg";
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

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = ["--cmd cd"];
      options = ["--cmd cd"];
    };

    zsh = {
      enable = true;
      shellAliases = {
        ".." = "cd ..";
        "..." = "cd ../..";
        ll = "ls -la";
        mc = "mc --nosubshell";
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
          "ohmyzsh/ohmyzsh path:plugins/fzf"
          "ohmyzsh/ohmyzsh path:plugins/git"
          "ohmyzsh/ohmyzsh path:plugins/rust"
          "ohmyzsh/ohmyzsh path:plugins/safe-paste"
          "ohmyzsh/ohmyzsh path:plugins/sudo"
          "ohmyzsh/ohmyzsh path:plugins/z"
          "ohmyzsh/ohmyzsh path:plugins/zoxide"

          # Community plugins
          "Aloxaf/fzf-tab"
          "MichaelAquilina/zsh-you-should-use"
          "romkatv/powerlevel10k"
          "zdharma-continuum/fast-syntax-highlighting"
          "zsh-users/zsh-autosuggestions"
          "zsh-users/zsh-completions"
          "zsh-users/zsh-history-substring-search"
        ];
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
