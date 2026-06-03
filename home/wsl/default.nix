{pkgs, ...}: {
  imports = [
    ../../modules/TUI/common
    ../../modules/TUI/zsh
    ../../modules/TUI/atuin
    ../../modules/GUI/terminal/wezterm
  ];

  home = {
    username = "zeev";
    homeDirectory = "/home/zeev";

    packages = with pkgs; [
      # Development tools
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

      # Security & Crypto
      pass

      # System & Monitoring tools
      nextdns
      pwgen
      sudo
      tmux
      tuptime

      # User utilities
      trash-cli
      tree
      yamllint
      zip
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
