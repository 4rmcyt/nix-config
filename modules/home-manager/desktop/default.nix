{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../GUI/firefox
    ../../GUI/thunderbird
    ../shared/common.nix
    ../shared/zsh.nix
  ];

  home = {
    username = "zeev";
    homeDirectory = "/home/zeev";
    stateVersion = "25.05";

    packages = with pkgs; [
      # Development tools
      bat
      busybox
      davfs2
      ffmpeg
      libva-utils
      pods
      pyenv
      python3
      vscode-fhs

      # Gaming
      steam
      vesktop

      # GUI applications
      ghostty
      jellyfin-media-player
      obsidian
      signal-desktop
      slack
      tail-tray
      tailscale
      ytmdesktop

      # KDE applications
      kdePackages.dolphin

      # Hardware monitoring
      nvtopPackages.nvidia

      # Security tools
      ccid
      pam_u2f
      pcsc-tools
      pinentry-qt

      # System information
      vdpauinfo
      vulkan-tools

      # Themes and icons
      gruvbox-dark-icons-gtk
      gruvbox-material-gtk-theme
      gruvbox-plus-icons
      kde-gruvbox

      # Browser with optimizations
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
    ];

    sessionVariables = {
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";
      XDG_CURRENT_DESKTOP = "KDE";
      NIXOS_OZONE_WL = "1";
      CLUTTER_BACKEND = "wayland";
      SDL_VIDEODRIVER = "wayland";
      XDG_SESSION_TYPE = "wayland";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";
      MOZ_DISABLE_RDD_SANDBOX = "1";
      QT_QPA_PLATFORM = "wayland;xcb";

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
        # Display options
        keyid-format = "long";
        with-keygrip = true;
        with-key-origin = true;
        with-fingerprint = true;
        with-subkey-fingerprint = true;

        # Security and verification
        require-cross-certification = true;
        no-symkey-cache = true;
        throw-keyids = true;

        # Algorithm preferences
        personal-cipher-preferences = "AES256 AES192 AES";
        personal-digest-preferences = "SHA512 SHA384 SHA256";
        personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
        default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";

        # Certificate preferences
        cert-digest-algo = "SHA512";
        s2k-digest-algo = "SHA512";
        s2k-cipher-algo = "AES256";

        # Charset and display
        charset = "utf-8";
        fixed-list-mode = true;
        no-comments = true;
        no-emit-version = true;
        no-greeting = true;
        keyserver-options = "no-honor-keyserver-url";
        list-options = "show-uid-validity";
        verify-options = "show-uid-validity";

        # Use agent
        use-agent = true;
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

    # tmux = {
    #   enable = true;
    #   baseIndex = 1;
    #   escapeTime = 0;
    #   historyLimit = 64096;
    #   keyMode = "vi";
    #   mouse = true;
    #   prefix = "C-Space";
    #   sensibleOnTop = false;
    #   terminal = "screen-256color";

    #   extraConfig = ''
    #     # Terminal settings
    #     set -ag terminal-overrides ",xterm-256color:RGB"
    #     set-option -g default-terminal "screen-256color"
    #     set-option -sa terminal-overrides ',xterm*:Tc'

    #     # Window and pane settings
    #     set-option -g renumber-windows on
    #     set-option -g automatic-rename on
    #     set-option -g automatic-rename-format '#{b:pane_current_path}'

    #     # Status line
    #     set-option -g status-position top

    #     # Key bindings
    #     bind-key x kill-pane
    #     bind-key X kill-window
    #     bind-key q confirm-before -p "kill-session #S? (y/n)" kill-session

    #     # Pane navigation
    #     bind h select-pane -L
    #     bind j select-pane -D
    #     bind k select-pane -U
    #     bind l select-pane -R

    #     # Pane resizing
    #     bind -r H resize-pane -L 10
    #     bind -r J resize-pane -D 10
    #     bind -r K resize-pane -U 10
    #     bind -r L resize-pane -R 10

    #     # Window splitting
    #     bind | split-window -h -c "#{pane_current_path}"
    #     bind - split-window -v -c "#{pane_current_path}"

    #     # Copy mode
    #     bind-key -T copy-mode-vi v send-keys -X begin-selection
    #     bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
    #     bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
    #   '';

    #   plugins = with pkgs.tmuxPlugins; [
    #     {
    #       plugin = resurrect;
    #       extraConfig = ''
    #         set -g @resurrect-strategy-vim 'session'
    #         set -g @resurrect-strategy-nvim 'session'
    #         set -g @resurrect-capture-pane-contents 'on'
    #       '';
    #     }
    #     {
    #       plugin = continuum;
    #       extraConfig = ''
    #         set -g @continuum-restore 'on'
    #         set -g @continuum-save-interval '10'
    #         set -g @continuum-save-bash-history 'on'
    #         set -g @continuum-save-zsh-history 'on'
    #       '';
    #     }
    #     vim-tmux-navigator
    #     yank
    #     {
    #       plugin = catppuccin;
    #       extraConfig = ''
    #         set -g @catppuccin_flavour 'mocha'
    #         set -g @catppuccin_window_left_separator ""
    #         set -g @catppuccin_window_right_separator " "
    #         set -g @catppuccin_window_middle_separator " █"
    #         set -g @catppuccin_window_number_position "right"
    #         set -g @catppuccin_window_default_fill "number"
    #         set -g @catppuccin_window_default_text "#W"
    #         set -g @catppuccin_window_current_fill "number"
    #         set -g @catppuccin_window_current_text "#W#{?window_zoomed_flag,(),}"
    #         set -g @catppuccin_status_modules_right "directory date_time"
    #         set -g @catppuccin_status_modules_left "session"
    #         set -g @catppuccin_status_left_separator  " "
    #         set -g @catppuccin_status_right_separator " "
    #         set -g @catppuccin_status_right_separator_inverse "no"
    #         set -g @catppuccin_status_fill "icon"
    #         set -g @catppuccin_status_connect_separator "no"
    #         set -g @catppuccin_directory_text "#{b:pane_current_path}"
    #         set -g @catppuccin_date_time_text "%H:%M"
    #       '';
    #     }
    #   ];
    # };
  };

  programs.zsh.sessionVariables = lib.mkMerge [
    {
      EDITOR = "hx";
    }
  ];

  services.gpg-agent.enable = true;
}
