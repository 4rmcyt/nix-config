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
    stateVersion = "24.11";

    packages = with pkgs; [
      # Development tools
      deploy-rs
      go
      nix-inspect
      nixfmt-tree
      pyenv

      # Fonts & Themes
      meslo-lgs-nf
      nerd-fonts.hack

      # Fun terminal utilities
      cowsay
      fortune

      # GUI applications (with Start Menu shortcuts)
      firefox
      ghostty
      ghostty.terminfo

      # Nix utilities
      nvd

      # Security & Crypto
      pass

      # System & Monitoring tools
      nextdns
      pwgen
      sudo
      tmux
      tuptime

      # User utilities
      borgbackup
      jq
      trash-cli
      tree
      unar
      yamllint
      zip

      # WSL-specific tools
      wslu
    ];
  };

  programs.zsh.enable = true;
  # Override zsh profile for pyenv
  programs.zsh.profileExtra = ''
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
  '';

  xdg = {
    enable = true;
    mimeApps.enable = true;
  };
}
