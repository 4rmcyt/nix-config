{pkgs, ...}: {
  imports = [
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

      # Audio tools
      cuetools
      shntool
      flac

      # Fonts
      meslo-lgs-nf

      # Nix utilities
      nvd

      # System & Network tools
      nextdns
      sudo
      tuptime

      # User utilities
      borgbackup
      jq
      pass
      trash-cli
      tree
      unar
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
}
