{
  pkgs,
  inputs,
  ...
}:
pkgs.mkShell {
  name = "nix-config";

  packages = with pkgs; [
    zsh
    nix-direnv

    nixfmt-rfc-style
    statix
    deadnix
    nix-tree
    nix-diff
    nix-output-monitor
    nix-prefetch-git
    nix-update
    nh
    nvd

    sops
    age
    ssh-to-age

    git
    gh

    inputs.deploy-rs.packages.${pkgs.stdenv.hostPlatform.system}.default

    shellcheck
    shfmt

    jq
    yq

    btop
    fd
    ripgrep
    bat
    eza

    just

    alejandra
    nurl

    pre-commit
    taplo
    yamlfmt
    ripsecrets

    rustc
    cargo
    rustfmt
    clippy
  ];

  shellHook = ''
    echo "🔨 NixOS Config Development Shell"

    if [[ $- == *i* ]] && [[ -z "$ZSH_VERSION" ]]; then
      exec zsh
    fi
  '';
}
