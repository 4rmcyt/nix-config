{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  home.username = "zeev";
  home.homeDirectory = "/home/zeev";
  home.stateVersion = "25.05";

  # ZSH Configuration
  programs = {
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
      };
      sessionVariables = {
        EDITOR = "nvim";
        ALTERNATE_EDITOR = "${pkgs.vim}/vin/vi";
        LC_CTYPE = "en_US.UTF-8";
        LEDGER_COLOR = "true";
        LESS = "-FRSXM";
        LESSCHARSET = "utf-8";
        PAGER = "less";
      };
      profileExtra = ''
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init --path)"
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

    # auto-cpufreq = {
    #   enable = true;
    #   settings = {
    #     charger = {
    #       governor = "performance";
    #       turbo = "auto";
    #     };
    #   };
    # };

    direnv = {
      enable = true;
      enableZshIntegration = true;
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
  };

  home.packages = with pkgs; [
    # Gaming
    steam
    discord
    lutris

    # Development
    vscode

    # GUI applications
    firefox
    kdePackages.dolphin
    nvtopPackages.nvidia
    jellyfin-media-player

    kdePackages.konsole
    kdePackages.kate
    kdePackages.ark
    kdePackages.okular
    kdePackages.gwenview
    kdePackages.spectacle
    kdePackages.kcalc
    kdePackages.kfind
    kdePackages.filelight
    kdePackages.partitionmanager
    kdePackages.discover
    kdePackages.kcharselect
    kdePackages.ksystemlog
    kdePackages.kclock
    kdePackages.sddm-kcm
    papirus-icon-theme
    kdePackages.breeze-icons
    kdiff3
    kdePackages.isoimagewriter
    hardinfo2

    # Wayland utilities
    wl-clipboard
    playerctl
    pavucontrol
    wayland-utils

    # Fonts
    nerd-fonts.fira-code

    mc
  ];

  # Configure Qt for Plasma 6
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "breeze";
  };

  # GTK configuration for better theme consistency with Plasma 6
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
    theme = {
      name = "Breeze";
      package = pkgs.kdePackages.breeze-gtk;
    };
  };

  programs.home-manager.enable = true;
}
