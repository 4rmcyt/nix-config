{pkgs, ...}: {
  imports = [
    ../shared/common.nix
    ../shared/zsh.nix
  ];

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
      go
      just
      nix-diff
      nix-fast-build
      nix-inspect
      nixfmt-rfc-style
      nixfmt-tree
      nil
      pyenv
      rustfmt
      shfmt
      statix

      # Editors
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

      # System & Monitoring tools
      btop
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
      jq
      p7zip
      trash-cli
      tree
      unar
      unzip
      yamllint
      zip

      # WSL-specific tools
      wslu
    ];
  };

  programs = {
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

  xdg = {
    enable = true;
    mimeApps.enable = true;
  };
}
