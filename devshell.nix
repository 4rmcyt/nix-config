{pkgs, ...}:
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
  ];

  shellHook = ''
    echo "🔨 NixOS Config Development Shell"
  '';
}
