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
      cowsay
      firefox
      fortune
      go
      meslo-lgs-nf
      nerd-fonts.hack
      nextdns
      nix-inspect
      nixfmt-tree
      pass
      pwgen
      pyenv
      sudo
      tmux
      trash-cli
      tree
      tuptime
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
