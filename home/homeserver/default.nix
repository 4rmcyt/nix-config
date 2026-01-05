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
      flac

      # Fonts
      meslo-lgs-nf

      # System & Network tools
      nextdns
      sudo
      tuptime

      # User utilities
      pass
      trash-cli
      tree
      yamllint
      zip
    ];
  };

  programs.zsh.enable = true;
  # Override zsh profile for pyenv and kubectl
  programs.zsh.profileExtra = ''
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"

    # k3s kubectl configuration
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
  '';
}
