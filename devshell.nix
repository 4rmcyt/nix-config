{pkgs, ...}:
pkgs.mkShell {
  name = "nix-config";

  packages = with pkgs; [
    age
    alejandra
    bat
    btop
    deadnix
    eza
    fd
    gh
    git
    gitleaks
    jq
    just
    nh
    nix-diff
    nix-direnv
    nix-output-monitor
    nix-prefetch-git
    nix-tree
    nix-update
    nixfmt
    nurl
    nvd
    pre-commit
    pre-commit-hook-ensure-sops
    ripgrep
    ripsecrets
    shellcheck
    shfmt
    sops
    ssh-to-age
    statix
    taplo
    yamlfmt
    yq
    zsh
  ];

  shellHook = ''
    echo "🔨 NixOS Config Development Shell"
  '';
}
