{
  pkgs,
  lib,
  ...
}:
# let
#   tmux2k = pkgs.tmuxPlugins.mkTmuxPlugin {
#     pluginName = "tmux2k";
#     version = "unstable-latest";
#     src = pkgs.fetchFromGitHub {
#       owner = "2kabhishek";
#       repo = "tmux2k";
#       rev = "master";
#       sha256 = "sha256-6dx81ItJodYUoWtlbGqoc5MPRCqy2PLgqIJK9lrAJ30";
#     };
#     rtpFilePath = "2k.tmux";
#   };
#   tmuxWhichKey = pkgs.tmuxPlugins.mkTmuxPlugin {
#     pluginName = "tmux-which-key";
#     version = "unstable-latest";
#     src = pkgs.fetchFromGitHub {
#       owner = "alexwforsythe";
#       repo = "tmux-which-key";
#       rev = "master";
#       sha256 = "1h830h9rz4d5pdr3ymmjjwaxg6sh9vi3fpsn0bh10yy0gaf6xcaz";
#     };
#     rtpFilePath = "plugin.sh.tmux";
#   };
# in
{
  imports = [
    ../../GUI/firefox
    ../../GUI/thunderbird
    # ../../GUI/zen-browser
  ];

  home = {
    username = "zeev";
    homeDirectory = "/home/zeev";
    stateVersion = "25.05";
    packages = with pkgs; [
      # Development
      bat
      pyenv
      python3
      vscode-fhs
      pods
      libva-utils
      home-manager
      busybox
      ffmpeg
      davfs2

      # Gaming
      vesktop
      steam
      #lutris

      # GUI applications
      ghostty
      jellyfin-media-player
      kdePackages.dolphin
      nvtopPackages.nvidia
      slack
      ytmdesktop
      pinentry-qt
      signal-desktop
      obsidian
      tailscale
      tail-tray

      # Themes and icons
      gruvbox-dark-icons-gtk
      gruvbox-material-gtk-theme
      gruvbox-plus-icons
      kde-gruvbox
      vdpauinfo
      vulkan-tools
      (chromium.override {
        enableWideVine = true;
        commandLineArgs = [
          "--enable-features=AcceleratedVideoEncoder,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE"
          "--enable-features=VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport"
          "--enable-features=UseMultiPlaneFormatForHardwareVideo"
          "--ignore-gpu-blocklist"
          "--enable-zero-copy"
        ];
      })
      pcsc-tools
      ccid
      pam_u2f
    ];

    sessionVariables = {
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";
      MOZ_DISABLE_RDD_SANDBOX = "1";

      BROWSER = lib.mkForce "firefox";
    };
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

  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    browserpass.enable = true;

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
      settings = {
        keyid-format = "long";
        with-keygrip = true;
        with-key-origin = true;
        with-fingerprint = true;
        with-subkey-fingerprint = true;
      };
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
      historyLimit = 50000000;
      plugins = with pkgs.tmuxPlugins; [
        extrakto
        fzf-tmux-url
        logging
        prefix-highlight
        sensible
        yank
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-boot 'on'
            set -g @continuum-save-interval '10'
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '0.5'
            set -g @continuum-save-bash-history 'on'
            set -g @continuum-save-zsh-history 'on'
            set -g @continuum-save-shell-history 'on'
          '';
        }
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
        # {
        #   plugin = tmux2k;
        #   extraConfig = ''
        #     set -g @tmux2k-theme 'onedark'
        #     set -g @tmux2k-left-plugins "session git"
        #     set -g @tmux2k-right-plugins "cpu ram network time"
        #   '';
        # }
        # {
        #   plugin = tmuxWhichKey;
        #   extraConfig = ''
        #     set -g @tmux-which-key-xdg-enable 1
        #     set -g @tmux-which-key-xdg-plugin-path=tmux/plugins/tmux-which-key
        #   '';
        # }
      ];

      extraConfig = ''
        set -g @super-fingers-key f
        set -g mouse on

        # easy-to-remember split pane commands
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"
        bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded.."
      '';
    };

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
        autoload -Uz compinit && compinit -d ~/.zcompdump

        # History substring search keybindings
        bindkey '^[[A' history-substring-search-up # or '\eOA'
        bindkey '^[[B' history-substring-search-down # or '\eOB'
        HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

        # Completion styles
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' menu no
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
        zstyle ':completion:*:*:docker:*' option-stacking yes
        zstyle ':completion:*:*:docker-*:*' option-stacking yes

        # Suppress completion errors for missing functions
        zstyle ':completion:*:functions' ignored-patterns '_*'

        # Load powerlevel10k theme
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
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
          "ohmyzsh/ohmyzsh path:plugins/fzf"
          "ohmyzsh/ohmyzsh path:plugins/git"
          "ohmyzsh/ohmyzsh path:plugins/poetry"
          "ohmyzsh/ohmyzsh path:plugins/pyenv"
          "ohmyzsh/ohmyzsh path:plugins/python"
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

    mpv = {
      enable = true;
      package = let
        mpv-jellyfin = pkgs.stdenv.mkDerivation {
          pname = "mpv-jellyfin";
          version = "main";

          src = pkgs.fetchFromGitHub {
            owner = "EmperorPenguin18";
            repo = "mpv-jellyfin";
            rev = "main";
            sha256 = "sha256-dli/YNDSbPYgu3navhpSTiJn17dqRxISVPZpw9yzbNc=";
          };

          dontBuild = true;

          installPhase = ''
            mkdir -p $out/share/mpv/scripts
            # List files to debug
            echo "Files in source directory:"
            find . -type f -name "*.lua" | head -20

            # Copy the actual lua file (check the repo structure)
            if [ -f "jellyfin.lua" ]; then
              cp jellyfin.lua $out/share/mpv/scripts/
            elif [ -f "src/jellyfin.lua" ]; then
              cp src/jellyfin.lua $out/share/mpv/scripts/
            elif [ -f "script/jellyfin.lua" ]; then
              cp script/jellyfin.lua $out/share/mpv/scripts/
            else
              # Find any lua file and copy it
              lua_file=$(find . -name "*.lua" | head -1)
              if [ -n "$lua_file" ]; then
                cp "$lua_file" $out/share/mpv/scripts/jellyfin.lua
              else
                echo "No Lua files found!"
                exit 1
              fi
            fi
          '';

          # Add the required scriptName attribute
          passthru.scriptName = "jellyfin.lua";
        };
      in
        pkgs.mpv-unwrapped.wrapper {
          scripts = with pkgs.mpvScripts; [
            uosc
            sponsorblock
            mpv-jellyfin
          ];

          mpv = pkgs.mpv-unwrapped.override {
            waylandSupport = true;
          };
        };

      config = {
        profile = "high-quality";
        ytdl-format = "bestvideo+bestaudio";
        cache-default = 4000000;

        # Jellyfin plugin configuration
        script-opts = "jellyfin-server=http://192.168.1.165:8096,jellyfin-username=admin";
      };
    };
  };

  services.gpg-agent.enable = true;
}
