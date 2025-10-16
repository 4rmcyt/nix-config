{
  pkgs,
  ...
}:
{
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
      deadnix
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

      # Fonts
      meslo-lgs-nf

      # Nix utilities
      nh
      nix-index
      nix-output-monitor
      nvd

      # Shell
      zsh-powerlevel10k

      # System & Network tools
      nextdns
      sudo
      tuptime

      # User utilities
      borgbackup
      dive
      jq
      p7zip
      pass
      trash-cli
      tree
      unar
      unzip
      yamllint
      zip
    ];
  };

  # Override zsh profile for pyenv
  programs.zsh.profileExtra = ''
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
  '';
}
