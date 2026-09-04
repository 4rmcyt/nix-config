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
    sessionVariables.PYENV_ROOT = "$HOME/.pyenv";

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

  # Override zsh profile for pyenv and kubectl
  programs.zsh.profileExtra = ''
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"

    # k3s kubectl configuration
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
  '';
}
