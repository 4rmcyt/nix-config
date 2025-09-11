{
  config,
  pkgs,
  inputs,
  ...
}:
{
  home.username = "zeev";
  home.homeDirectory = "/home/zeev";
  home.stateVersion = "25.05";

  # ZSH Configuration (same as before)
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };

    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      mc = "mc --nosubshell";
    };

    initContent = ''
      # Custom prompt
      autoload -U colors && colors
      PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "

      # Auto cd
      setopt autocd

      # Better history
      setopt histignorealldups sharehistory

      # Use vim bindings
      bindkey -v

      # Better completion
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}

      # Load environment if it exists
      if [ -f ~/.env ]; then
        source ~/.env
      fi
    '';
  };

  # Terminal - Using Konsole (KDE's terminal) as default but keep Kitty available
  programs.kitty = {
    enable = true;
    settings = {
      shell = "zsh";
      window_padding_width = 10;
      scrollback_lines = 10000;
      show_hyperlink_targets = "yes";
      enable_audio_bell = false;
      url_style = "none";
      underline_hyperlinks = "never";
      copy_on_select = "clipboard";
      # KDE integration
      confirm_os_window_close = 0;
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

    # KDE-specific utilities  
    kdePackages.konsole
    kdePackages.kate
    kdePackages.ark
    kdePackages.okular
    kdePackages.gwenview
    kdePackages.spectacle
    kdePackages.kcalc
    kdePackages.kfind
    kdePackages.filelight

    # System utilities
    grim
    slurp
    wl-clipboard
    playerctl
    pavucontrol

    # Fonts
    nerd-fonts.fira-code

    # Icon themes and packages for KDE
    papirus-icon-theme
    breeze-icons
    oxygen-icons5
  ];

  # Configure KDE/Qt applications
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "breeze";
  };

  # GTK configuration for better theme consistency
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

  programs.git = {
    enable = true;
    userName = "4rmcyt";
    userEmail = "4rmcyt@gmail.com";
  };

  programs.home-manager.enable = true;
}