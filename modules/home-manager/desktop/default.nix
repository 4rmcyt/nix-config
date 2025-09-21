{
  pkgs,
  lib,
  ...
}:
{
  home = {
    username = "zeev";
    homeDirectory = "/home/zeev";
    stateVersion = "25.05";
    packages = with pkgs; [
      # Gaming
      steam
      discord
      lutris

      # Development
      vscode-fhs
      pyenv

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
    ];
  };

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
        EDITOR = "hx";
        ALTERNATE_EDITOR = "${pkgs.vim}/bin/vi"; # Fixed typo: vin -> bin
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

        bindkey '^[[A' history-substring-search-up # or '\eOA'
        bindkey '^[[B' history-substring-search-down # or '\eOB'
        HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

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

    tmux = {
      enable = true;
      shell = "${pkgs.zsh}/bin/zsh";
      shortcut = "b";
      aggressiveResize = true;
      baseIndex = 1;
      newSession = true;
      escapeTime = 0;
      secureSocket = false;
      mouse = true;
      clock24 = true;
      historyLimit = 500000;
      plugins = with pkgs.tmuxPlugins; [
        better-mouse-mode
        # tmux-cowboy # Doesn't exist
        # tmux-menus # Doesn't exist
        fzf-tmux-url
        resurrect
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-boot 'on'
            set -g @continuum-save-interval '10'
          '';
        }

        # tmux-mem-cpu-load
        prefix-highlight
        logging
        extrakto
        sensible
        tmux-cpu
        
        yank
        {
          plugin = dracula;
          extraConfig = ''
            set -g @dracula-show-battery false
            set -g @dracula-show-powerline true
            set -g @dracula-refresh-rate 10
          '';
        }
      ];

      extraConfig = ''
        # https://old.reddit.com/r/tmux/comments/mesrci/tmux_2_doesnt_seem_to_use_256_colors/
        set -g default-terminal "tmux-256color"
        set -ga terminal-overrides ",*256col*:Tc"
        set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
        set-environment -g COLORTERM "truecolor"


        set -g status-right '#{cpu_bg_color} CPU: #{cpu_icon} #{cpu_percentage} | %a %h-%d %H:%M '
        set -ga update-environment EDITOR
        set -g @super-fingers-key f
        set -g @plugin 'dracula/tmux'
        set -g mouse on


        # easy-to-remember split pane commands
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"
      '';
    };
  };

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
}
