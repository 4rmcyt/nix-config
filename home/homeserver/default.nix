{pkgs, ...}: {
  imports = [
    ../../modules/TUI/ai-tools
    ../../modules/TUI/common
    ../../modules/dev/git.nix
    ../../modules/security/gpg.nix
    ../../modules/TUI/helix
    ../../modules/TUI/neovim
    ../../modules/TUI/zsh
    ../../modules/TUI/starship
    ../../modules/TUI/atuin
    ../../modules/TUI/zellij
  ];

  programs.starship.presets = ["bracketed-segments"];
  programs.starship.settings = {
    git_status = {
      stashed = "";
      untracked = "";
      modified = builtins.fromJSON ''"\uEB43 "''; # nf-cod-request_changes
    };
    custom.nix = {
      detect_files = ["flake.nix"];
      symbol = builtins.fromJSON ''"\uF313 "''; # nf-linux-nixos
      format = "\\[[$symbol]($style)\\]";
      style = "bold blue";
    };
  };

  home = {
    sessionVariables = {
      KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
    };

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
      trash-cli
      tree
      tuptime
      yamllint
      zip
      dmidecode
      pkg-config
    ];
  };

  programs.zsh.profileExtra = ''
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
  '';
}
