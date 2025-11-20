{pkgs, ...}: {
  imports = [
    ../../modules/GUI/ghostty
    ../../modules/TUI/common
    ../../modules/TUI/zsh
    ../../modules/TUI/atuin
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

      # Fonts & Themes (dev tools like vim, neovim, nh, nix-index, zsh-powerlevel10k, pinentry-tty moved to shared/dev-tools.nix)
      meslo-lgs-nf
      nerd-fonts.hack

      # Fun terminal utilities
      cowsay
      fortune

      # GUI applications (with Start Menu shortcuts)
      firefox
      ghostty
      ghostty.terminfo
      obsidian

      # Nix utilities
      nix-output-monitor
      nvd

      # Security & Crypto
      gnupg
      pass

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
    # ghostty configuration moved to shared module: ../../modules/GUI/ghostty
    zsh.enable = true;
  };

  xdg = {
    enable = true;
    mimeApps.enable = true;
  };
}
