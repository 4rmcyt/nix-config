{pkgs, ...}: {
  imports = [
    ../../modules/TUI/ai-tools
    ../../modules/TUI/common
    ../../modules/dev/git.nix
    ../../modules/security/gpg.nix
    ../../modules/TUI/helix
    ../../modules/TUI/neovim
    ../../modules/TUI/zsh
    ../../modules/TUI/atuin
    ../../modules/TUI/zellij
  ];

  home = {
    packages = with pkgs; [
      cuetools
      flac
      go
      meslo-lgs-nf
      nextdns
      nix-inspect
      nixfmt-tree
      pass
      pyenv
      sudo
      trash-cli
      tree
      tuptime
      yamllint
      zip
    ];
  };

  programs.zsh.profileExtra = ''
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
  '';
}
