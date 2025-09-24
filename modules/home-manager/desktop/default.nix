# TODO: Make separated tmux configuration module
{
  pkgs,
  lib,
  ...
}:
let
  tmux2k = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux2k";
    version = "unstable-latest";
    src = pkgs.fetchFromGitHub {
      owner = "2kabhishek";
      repo = "tmux2k";
      rev = "master";
      sha256 = "sha256-6dx81ItJodYUoWtlbGqoc5MPRCqy2PLgqIJK9lrAJ30=";
    };
    rtpFilePath = "2k.tmux";
  };

  tmuxWhichKey = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-which-key";
    version = "unstable-latest";
    src = pkgs.fetchFromGitHub {
      owner = "alexwforsythe";
      repo = "tmux-which-key";
      rev = "master";
      sha256 = "sha256-1h830h9rz4d5pdr3ymmjjwaxg6sh9vi3fpsn0bh10yy0gaf6xcaz";
    };
    rtpFilePath = "plugin.sh.tmux";
  };
in
{
  # =================================================================
  # 1. HOME CONFIGURATION
  # =================================================================

  home = {
    username = "zeev";
    homeDirectory = "/home/zeev";
    stateVersion = "25.05";

    packages = with pkgs; [
      # Development Tools
      vscode-fhs
      pyenv
      bat
      python3
      ghostty

      # Gaming
      steam
      discord
      lutris

      # GUI Applications
      firefox
      kdePackages.dolphin
      slack
      nvtopPackages.nvidia
      jellyfin-media-player
      ytmdesktop

      # Themes & Appearance
      gruvbox-material-gtk-theme
      gruvbox-plus-icons
      gruvbox-dark-icons-gtk
      kde-gruvbox
      sddm-sugar-dark
    ];
  };

  # =================================================================
  # 2. PROGRAMS CONFIGURATION
  # =================================================================

  programs = {
    # --- Version Control ---
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

    # --- Shell & Terminal ---
    zsh = {
      enable = true;
      shellAliases = {
        ll = "ls -la";
        mc = "mc --nosubshell";
      };
      sessionVariables = {
        EDITOR = "hx";
        ALTERNATE_EDITOR = "${pkgs.vim}/bin/vi";
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

        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
        HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' menu no
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
        zstyle ':completion:*:*:docker:*' option-stacking yes
        zstyle ':completion:*:*:docker-*:*' option-stacking yes

        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        if [ $(command -v fortune) ] && [ $UID != '0' ] && [[ $- == *i* ]] && [ $TERM != 'dumb' ]; then
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

    ghostty = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        theme = "Dracula+";
        background-blur-radius = 40;
        background-opacity = 0.50;
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

    # --- Development Tools ---
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

    # --- Utilities ---
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

    # --- Applications ---
    firefox = {
      enable = true;
      profiles.default = {
        settings = {
          # Disable disk cache, use RAM only
          "browser.cache.disk.enable" = false;
          "browser.cache.memory.enable" = true;
          "browser.cache.memory.capacity" = 524288; # 512MB

          # Reduce session store frequency
          "browser.sessionstore.interval" = 300000; # 5 minutes

          # Disable crash reporter disk writes
          "toolkit.crashreporter.enabled" = false;

          # Reduce various disk writes
          "browser.download.manager.retention" = 0;
          "browser.helperApps.deleteTempFileOnExit" = true;

          # Disable safebrowsing disk cache
          "browser.safebrowsing.provider.google4.dataSharingURL" = "";
        };
      };
    };

    # --- Terminal Multiplexer ---
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
      historyLimit = 50000000;

      plugins = with pkgs.tmuxPlugins; [
        # Core plugins
        sensible
        yank

        # Navigation & UI
        fzf-tmux-url
        prefix-highlight
        extrakto

        # Session management
        {
          plugin = resurrect;
          extraConfig = ''
            set -g @resurrect-strategy-nvim 'session'
            set -g @resurrect-processes 'vim nvim hx cat less more tail watch'
            resurrect_dir=~/.config/tmux/resurrect
            set -g @resurrect-dir $resurrect_dir
            set -g @resurrect-hook-post-save-all "sed -i 's| --cmd .*-vim-pack-dir||g; s|/etc/profiles/per-user/$USER/bin/||g; s|/nix/store/.*/bin/||g' $(readlink -f $resurrect_dir/last)"
            set -g @resurrect-save 'S'
            set -g @resurrect-restore 'R'
            set -g @resurrect-save-bash-history 'on'
            set -g @resurrect-save-zsh-history 'on'
            set -g @resurrect-save-shell-history 'on'
            set -g @resurrect-capture-pane-contents 'on'
          '';
        }

        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-boot 'on'
            set -g @continuum-save-interval '10'
            set -g @continuum-save-bash-history 'on'
            set -g @continuum-save-zsh-history 'on'
            set -g @continuum-save-shell-history 'on'
          '';
        }

        # Logging
        logging

        # Theme & UI plugins
        {
          plugin = tmux2k;
          extraConfig = ''
            set -g @tmux2k-theme 'onedark'
            set -g @tmux2k-left-plugins "session git"
            set -g @tmux2k-right-plugins "cpu ram network time"
          '';
        }

        {
          plugin = tmuxWhichKey;
          extraConfig = ''
            set -g @tmux-which-key-xdg-enable 1
            set -g @tmux-which-key-xdg-plugin-path=tmux/plugins/tmux-which-key
          '';
        }
      ];

      extraConfig = ''
        set -g @super-fingers-key f
        set -g mouse on

        # Easy-to-remember split pane commands
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"
        bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded.."
      '';
    };
  };

  # =================================================================
  # 3. THEME CONFIGURATION
  # =================================================================

  # Qt configuration for Plasma 6
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "breeze";
  };

  # GTK configuration for better theme consistency with Plasma 6
  gtk = {
    enable = true;
    iconTheme = {
      name = "Gruvbox-Dark";
      package = pkgs.gruvbox-dark-icons-gtk;
    };
    theme = {
      name = "breeze_transparent_dark";
      package = pkgs.kdePackages.breeze-gtk;
    };
  };
}
